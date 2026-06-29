import {
  ENGINE,
  type EpisodePlan,
  type TokenUsage,
} from '@doubles/shared';
import type { Clock, Db, Logger, NewBeat, NewRecap } from './ports.js';
import type { AIClient } from './ai/AIClient.js';
import { zeroUsage } from './ai/AIClient.js';
import type { Moderator } from './moderation/Moderator.js';
import type { Notifier, Notification } from './notify/Notifier.js';
import type { WorldContext, CastMember } from './context.js';
import { resolveBet, isFinalEpisode } from './game/index.js';

export interface EngineConfig {
  beatCap: number;
  tokenBudget: number;
  totalEpisodes: number;
}

export interface EngineDeps {
  db: Db;
  ai: AIClient;
  moderator: Moderator;
  notifier: Notifier;
  clock: Clock;
  logger: Logger;
  config?: Partial<EngineConfig>;
}

export interface RunEpisodeResult {
  status: 'published' | 'noop' | 'failed';
  episodeNumber: number;
  beatsPublished: number;
  blockedBeats: number;
  tokenUsage: TokenUsage;
  reason?: string;
}

/**
 * Orchestrates the nightly pipeline (brief §6 stages 1–9) for one world, with an
 * idempotency guard so re-running a published episode is a no-op. Pure w.r.t.
 * injected ports — no framework or DB imports beyond the Db interface.
 */
export async function runEpisode(deps: EngineDeps, worldId: string): Promise<RunEpisodeResult> {
  const { db, ai, moderator, notifier, clock, logger } = deps;
  const cfg: EngineConfig = {
    beatCap: deps.config?.beatCap ?? ENGINE.DEFAULT_BEAT_CAP,
    tokenBudget: deps.config?.tokenBudget ?? ENGINE.DEFAULT_TOKEN_BUDGET,
    totalEpisodes: deps.config?.totalEpisodes ?? 14,
  };

  const world = await db.getWorld(worldId);
  if (!world) {
    return failure(0, 'world not found');
  }
  if (world.seasonStatus === 'ended') {
    return failure(world.currentEpisode, 'season ended');
  }

  const episodeNumber = world.currentEpisode + 1;

  // --- idempotency guard ---
  const existing = await db.getEpisodeByNumber(worldId, episodeNumber);
  if (existing?.status === 'published') {
    logger.info('runEpisode noop — already published', { worldId, episodeNumber });
    return { status: 'noop', episodeNumber, beatsPublished: 0, blockedBeats: 0, tokenUsage: zeroUsage() };
  }

  // === Stage 1: gather ===
  const context = await gather(db, worldId, world, episodeNumber, cfg.beatCap);
  if (context.cast.length === 0) {
    return failure(episodeNumber, 'no active doubles in world');
  }

  const episode = existing ?? (await db.createEpisode(worldId, episodeNumber));
  let usage = zeroUsage();

  try {
    // === Stage 2: plan ===
    await db.setEpisodeStatus(episode.id, 'planning');
    const planResult = await ai.planEpisode(context);
    const plan = planResult.plan;
    usage = addUsage(usage, planResult.usage);

    // Enforce the beat cap (graceful degradation under budget pressure).
    let plannedBeats = plan.beats.slice(0, cfg.beatCap);
    if (usage.outputTokens + usage.inputTokens > cfg.tokenBudget) {
      logger.warn('token budget exceeded after planning — trimming beats', { worldId });
      plannedBeats = plannedBeats.slice(0, Math.ceil(cfg.beatCap / 2));
    }

    // === Stage 3: generate ===
    await db.setEpisodeStatus(episode.id, 'generating');
    const gen = await ai.generateBeats(plannedBeats, context);
    usage = addUsage(usage, gen.usage);

    // === Stage 4: moderate ===
    await db.setEpisodeStatus(episode.id, 'moderating');
    const handleToId = new Map(context.cast.map((c) => [c.handle, c.doubleId]));
    const okBeats: NewBeat[] = [];
    let blocked = 0;
    const modEvents = [];
    for (const planned of plannedBeats) {
      const generated = gen.beats.find((b) => b.ref === planned.ref);
      if (!generated) continue;
      const verdict = await moderator.check(generated.content, 'beat');
      modEvents.push({
        subjectType: 'beat' as const,
        subjectId: planned.ref,
        verdict: verdict.verdict,
        reason: verdict.reason,
      });
      if (verdict.verdict === 'blocked') {
        blocked++;
        continue;
      }
      const participantDoubleIds = planned.participants
        .map((h) => handleToId.get(h.replace(/^@/, '')) ?? (isUuid(h) ? h : null))
        .filter((id): id is string => id !== null);
      okBeats.push({
        kind: planned.kind,
        participantDoubleIds,
        content: generated.content,
        visibility: planned.visibility,
        moderationStatus: 'ok',
      });
    }
    await db.recordModerationEvents(modEvents);

    // === Stage 5: applyState ===
    const insertedBeats = await db.insertBeats(episode.id, worldId, okBeats);
    await db.setEpisodeHeadline(episode.id, plan.headline);
    if (plan.relationshipDeltas.length) {
      await db.applyRelationshipDeltas(
        worldId,
        plan.relationshipDeltas.map((d) => ({
          fromDoubleId: d.fromDoubleId,
          toDoubleId: d.toDoubleId,
          delta: d.delta,
          type: d.type,
        })),
      );
    }
    if (plan.agendaOutcomes.length) {
      await db.markAgendaOutcomes(
        plan.agendaOutcomes.map((o) => ({ agendaId: o.agendaId, status: o.status })),
      );
    }
    if (plan.proposedMarkets.length) {
      await db.insertMarkets(
        worldId,
        episodeNumber,
        plan.proposedMarkets.map((m) => ({
          question: m.question,
          options: m.options,
          resolvesOnEpisode: m.resolvesOnEpisode,
          multiplier: m.multiplier,
        })),
      );
    }
    if (plan.consumedPowerMoveIds.length) {
      await db.markPowerMovesApplied(plan.consumedPowerMoveIds);
    }

    // === Stage 6: resolveBets (deterministic, no AI) ===
    await resolveBets(db, worldId, episodeNumber, plan, logger);

    // === Stage 7: score ===
    if (plan.scoreDeltas.length) {
      await db.applyScoreDeltas(
        worldId,
        plan.scoreDeltas.map((s) => ({
          doubleId: s.doubleId,
          drama: s.drama,
          ships: s.ships,
          glowup: s.glowup,
          villain: s.villain,
        })),
      );
    }
    if (isFinalEpisode(episodeNumber, cfg.totalEpisodes)) {
      await db.setSeasonStatus(worldId, 'finale');
      logger.info('season finale reached', { worldId, episodeNumber });
    }

    // === Stage 8: buildRecaps ===
    const recapUsage = await buildRecaps(
      deps,
      worldId,
      episode.id,
      episodeNumber,
      world.name,
      plan,
      insertedBeats,
    );
    usage = addUsage(usage, recapUsage);

    // === Stage 9: notify ===
    const users = await db.getWorldUsers(worldId);
    const notifications: Notification[] = users.map((u) => ({
      userId: u.userId,
      worldId,
      episodeNumber,
      title: `Episode ${episodeNumber} is live`,
      body: `Your double did something. ${plan.headline}`,
    }));
    await notifier.enqueue(notifications);

    // --- publish (also bumps world.current_episode) ---
    await db.publishEpisode(episode.id, worldId, episodeNumber, {
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      cachedInputTokens: usage.cachedInputTokens,
      calls: usage.calls,
    });

    logger.info('episode published', {
      worldId,
      episodeNumber,
      beats: insertedBeats.length,
      blocked,
    });

    return {
      status: 'published',
      episodeNumber,
      beatsPublished: insertedBeats.length,
      blockedBeats: blocked,
      tokenUsage: usage,
    };
  } catch (err) {
    logger.error('runEpisode failed', { worldId, episodeNumber, error: String(err) });
    await db.setEpisodeStatus(episode.id, 'failed').catch(() => undefined);
    return { status: 'failed', episodeNumber, beatsPublished: 0, blockedBeats: 0, tokenUsage: usage, reason: String(err) };
  }

  function failure(n: number, reason: string): RunEpisodeResult {
    logger.warn('runEpisode aborted', { worldId, reason });
    return { status: 'failed', episodeNumber: n, beatsPublished: 0, blockedBeats: 0, tokenUsage: zeroUsage(), reason };
  }
}

// ---- Stage 1 ----
async function gather(
  db: Db,
  worldId: string,
  world: { name: string; vibe: string; seasonNumber: number },
  episodeNumber: number,
  beatCap: number,
): Promise<WorldContext> {
  const [doubles, relationships, agendas, recent, powerMoves, markets] = await Promise.all([
    db.getActiveDoubles(worldId),
    db.getRelationships(worldId),
    db.getPendingAgendas(worldId, episodeNumber),
    db.getRecentEpisodes(worldId, ENGINE.RECENT_EPISODE_WINDOW),
    db.getQueuedPowerMoves(worldId, episodeNumber),
    db.getMarketsResolvingOn(worldId, episodeNumber),
  ]);

  const cast: CastMember[] = doubles.map((d) => ({
    doubleId: d.id,
    displayName: d.displayName,
    handle: d.handle,
    persona: d.personaPrompt,
    traits: d.traits,
  }));
  const handleOf = new Map(doubles.map((d) => [d.id, d.handle]));

  return {
    worldId,
    worldName: world.name,
    vibe: world.vibe,
    seasonNumber: world.seasonNumber,
    episodeNumber,
    cast,
    relationships: relationships.map((r) => ({
      fromDoubleId: r.fromDoubleId,
      toDoubleId: r.toDoubleId,
      fromHandle: handleOf.get(r.fromDoubleId) ?? '?',
      toHandle: handleOf.get(r.toDoubleId) ?? '?',
      affinity: r.affinity,
      type: r.type,
    })),
    agendas: agendas.map((a) => ({
      agendaId: a.id,
      doubleId: a.doubleId,
      handle: handleOf.get(a.doubleId) ?? '?',
      intent: a.intentText,
    })),
    recentEpisodeSummaries: recent
      .filter((e) => e.status === 'published')
      .map((e) => ({ number: e.number, headline: e.headline ?? `Episode ${e.number}` })),
    marketsResolvingNow: markets.map((m) => ({
      id: m.id,
      question: m.question,
      options: m.options,
    })),
    queuedPowerMoves: powerMoves.map((p) => ({
      id: p.id,
      type: p.type,
      ownerDoubleId: findOwnerDoubleId(doubles, p.userId),
      ownerHandle: handleForUser(doubles, p.userId),
      targetDoubleId: p.targetDoubleId,
      targetHandle: p.targetDoubleId ? (handleOf.get(p.targetDoubleId) ?? null) : null,
      payload: p.payload,
    })),
    beatCap,
  };
}

// ---- Stage 6 ----
async function resolveBets(
  db: Db,
  worldId: string,
  episodeNumber: number,
  plan: EpisodePlan,
  logger: Logger,
): Promise<void> {
  const markets = await db.getMarketsResolvingOn(worldId, episodeNumber);
  for (const market of markets) {
    const resolution = plan.marketResolutions.find((r) => r.marketId === market.id);
    if (!resolution) {
      await db.resolveMarket(market.id, null, true); // void if planner gave no outcome
      logger.warn('market voided — no resolution from planner', { marketId: market.id });
      continue;
    }
    await db.resolveMarket(market.id, resolution.winningOption);
    const bets = await db.getOpenBetsForMarket(market.id);
    for (const bet of bets) {
      const outcome = resolveBet(bet.stakeClout, bet.optionKey, resolution.winningOption, market.multiplier);
      await db.settleBet(bet.id, outcome.won ? 'won' : 'lost', episodeNumber);
      if (outcome.delta !== 0) {
        await db.adjustClout(bet.userId, worldId, outcome.delta);
      }
    }
  }
}

// ---- Stage 8 ----
async function buildRecaps(
  deps: EngineDeps,
  worldId: string,
  episodeId: string,
  episodeNumber: number,
  worldName: string,
  plan: EpisodePlan,
  insertedBeats: { id: string; participantDoubleIds: string[]; content: string; visibility: string; kind: string }[],
): Promise<TokenUsage> {
  const { db, ai } = deps;
  let usage = zeroUsage();
  const users = await db.getWorldUsers(worldId);
  for (const user of users) {
    const mine = insertedBeats.filter((b) => b.participantDoubleIds.includes(user.double.id));
    const publicBeats = mine.filter((b) => b.visibility === 'public');
    const gatedBeatIds = mine.filter((b) => b.visibility === 'reveal_gated').map((b) => b.id);

    const recapOut = await ai.writeRecap({
      userHandle: user.double.handle,
      episodeNumber,
      worldName,
      headline: plan.headline,
      relevantBeats: publicBeats.map((b) => ({ kind: b.kind, content: b.content })),
      worldHeadlines: [plan.headline],
    });
    usage = addUsage(usage, recapOut.usage);

    const recap: NewRecap = {
      userId: user.userId,
      narrative: recapOut.recap.narrative,
      highlights: recapOut.recap.highlights,
      gatedBeatIds,
    };
    await db.upsertRecap(episodeId, recap);
  }
  return usage;
}

// ---- helpers ----
function addUsage(a: TokenUsage, b: TokenUsage): TokenUsage {
  return {
    inputTokens: a.inputTokens + b.inputTokens,
    outputTokens: a.outputTokens + b.outputTokens,
    cachedInputTokens: a.cachedInputTokens + b.cachedInputTokens,
    calls: a.calls + b.calls,
  };
}

function isUuid(s: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
}

function findOwnerDoubleId(
  doubles: { id: string; ownerUserId: string }[],
  userId: string,
): string | null {
  return doubles.find((d) => d.ownerUserId === userId)?.id ?? null;
}

function handleForUser(
  doubles: { handle: string; ownerUserId: string }[],
  userId: string,
): string | null {
  return doubles.find((d) => d.ownerUserId === userId)?.handle ?? null;
}
