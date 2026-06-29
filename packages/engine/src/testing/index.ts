import { randomUUID } from 'node:crypto';
import type {
  Double,
  World,
  Relationship,
  Agenda,
  Episode,
  Beat,
  Market,
  Bet,
  PowerMove,
  SeasonScore,
} from '@doubles/shared';
import { clampAffinity } from '../game/index.js';
import type {
  Clock,
  Db,
  Logger,
  NewBeat,
  NewMarket,
  NewRecap,
  ModerationEventWrite,
  RelationshipDeltaWrite,
  ScoreDeltaWrite,
  WorldUserDouble,
} from '../ports.js';

/** Fixed clock for deterministic tests. */
export class FixedClock implements Clock {
  constructor(private readonly fixed: Date = new Date('2026-01-01T00:00:00Z')) {}
  now(): Date {
    return this.fixed;
  }
}

export class SystemClock implements Clock {
  now(): Date {
    return new Date();
  }
}

export class SilentLogger implements Logger {
  info(): void {}
  warn(): void {}
  error(): void {}
}

export class ConsoleLogger implements Logger {
  info(msg: string, meta?: Record<string, unknown>): void {
    console.log(`[info] ${msg}`, meta ?? '');
  }
  warn(msg: string, meta?: Record<string, unknown>): void {
    console.warn(`[warn] ${msg}`, meta ?? '');
  }
  error(msg: string, meta?: Record<string, unknown>): void {
    console.error(`[error] ${msg}`, meta ?? '');
  }
}

const iso = () => new Date().toISOString();

/**
 * Fully in-memory Db implementation. Used by engine unit/integration tests and
 * usable as a reference for the Supabase adapter in @doubles/db. Implements the
 * exact same Db port the production code injects.
 */
export class InMemoryDb implements Db {
  users: { id: string }[] = [];
  doubles: Double[] = [];
  worlds: World[] = [];
  members: { worldId: string; doubleId: string }[] = [];
  relationships: Relationship[] = [];
  agendas: Agenda[] = [];
  episodes: Episode[] = [];
  beats: Beat[] = [];
  markets: Market[] = [];
  bets: Bet[] = [];
  powerMoves: PowerMove[] = [];
  clout: { userId: string; worldId: string; balance: number }[] = [];
  scores: SeasonScore[] = [];
  recaps: { episodeId: string; userId: string; narrative: string; highlights: string[]; gatedBeatIds: string[] }[] = [];
  moderationEvents: ModerationEventWrite[] = [];

  // ---- seeding helpers ----
  addUser(id = randomUUID()): string {
    this.users.push({ id });
    return id;
  }

  addDouble(d: Partial<Double> & { ownerUserId: string; displayName: string; handle: string }): Double {
    const full: Double = {
      id: d.id ?? randomUUID(),
      ownerUserId: d.ownerUserId,
      displayName: d.displayName,
      handle: d.handle,
      personaPrompt: d.personaPrompt ?? `${d.displayName} is a character.`,
      traits: d.traits ?? {},
      avatarSeed: d.avatarSeed ?? d.handle,
      moderationStatus: d.moderationStatus ?? 'ok',
      createdAt: iso(),
      updatedAt: iso(),
    };
    this.doubles.push(full);
    return full;
  }

  addWorld(w: Partial<World> & { name: string; createdBy: string }): World {
    const full: World = {
      id: w.id ?? randomUUID(),
      name: w.name,
      vibe: w.vibe ?? 'messy',
      createdBy: w.createdBy,
      seasonNumber: w.seasonNumber ?? 1,
      seasonStatus: w.seasonStatus ?? 'active',
      currentEpisode: w.currentEpisode ?? 0,
      seasonEndsAt: w.seasonEndsAt ?? null,
      createdAt: iso(),
    };
    this.worlds.push(full);
    return full;
  }

  addMember(worldId: string, doubleId: string): void {
    this.members.push({ worldId, doubleId });
  }

  setClout(userId: string, worldId: string, balance: number): void {
    const row = this.clout.find((c) => c.userId === userId && c.worldId === worldId);
    if (row) row.balance = balance;
    else this.clout.push({ userId, worldId, balance });
  }

  // ---- Db port: reads ----
  async getWorld(worldId: string): Promise<World | null> {
    return this.worlds.find((w) => w.id === worldId) ?? null;
  }

  async getActiveDoubles(worldId: string): Promise<Double[]> {
    const ids = new Set(this.members.filter((m) => m.worldId === worldId).map((m) => m.doubleId));
    return this.doubles.filter((d) => ids.has(d.id) && d.moderationStatus !== 'blocked');
  }

  async getWorldUsers(worldId: string): Promise<WorldUserDouble[]> {
    const doubles = await this.getActiveDoubles(worldId);
    return doubles.map((d) => ({ userId: d.ownerUserId, double: d }));
  }

  async getRelationships(worldId: string): Promise<Relationship[]> {
    return this.relationships.filter((r) => r.worldId === worldId);
  }

  async getPendingAgendas(worldId: string, targetEpisode: number): Promise<Agenda[]> {
    return this.agendas.filter(
      (a) => a.worldId === worldId && a.targetEpisode === targetEpisode && a.status === 'pending',
    );
  }

  async getRecentEpisodes(worldId: string, limit: number): Promise<Episode[]> {
    return this.episodes
      .filter((e) => e.worldId === worldId)
      .sort((a, b) => b.number - a.number)
      .slice(0, limit);
  }

  async getQueuedPowerMoves(worldId: string, applyOnEpisode: number): Promise<PowerMove[]> {
    return this.powerMoves.filter(
      (p) => p.worldId === worldId && p.applyOnEpisode === applyOnEpisode && p.status === 'queued',
    );
  }

  async getEpisodeByNumber(worldId: string, number: number): Promise<Episode | null> {
    return this.episodes.find((e) => e.worldId === worldId && e.number === number) ?? null;
  }

  // ---- Db port: episode lifecycle ----
  async createEpisode(worldId: string, number: number): Promise<Episode> {
    const ep: Episode = {
      id: randomUUID(),
      worldId,
      number,
      status: 'planning',
      headline: null,
      tokenUsage: null,
      generatedAt: null,
      publishedAt: null,
    };
    this.episodes.push(ep);
    return ep;
  }

  async setEpisodeStatus(episodeId: string, status: Episode['status']): Promise<void> {
    const ep = this.episodes.find((e) => e.id === episodeId);
    if (ep) ep.status = status;
  }

  async setEpisodeHeadline(episodeId: string, headline: string): Promise<void> {
    const ep = this.episodes.find((e) => e.id === episodeId);
    if (ep) ep.headline = headline;
  }

  async publishEpisode(
    episodeId: string,
    worldId: string,
    number: number,
    tokenUsage: Record<string, number>,
  ): Promise<void> {
    const ep = this.episodes.find((e) => e.id === episodeId);
    if (ep) {
      ep.status = 'published';
      ep.tokenUsage = tokenUsage;
      ep.generatedAt = iso();
      ep.publishedAt = iso();
    }
    const world = this.worlds.find((w) => w.id === worldId);
    if (world) world.currentEpisode = number;
  }

  // ---- Db port: applyState ----
  async insertBeats(episodeId: string, worldId: string, beats: NewBeat[]): Promise<Beat[]> {
    const created = beats.map((b) => ({
      id: randomUUID(),
      episodeId,
      worldId,
      kind: b.kind,
      participantDoubleIds: b.participantDoubleIds,
      content: b.content,
      visibility: b.visibility,
      moderationStatus: b.moderationStatus,
      createdAt: iso(),
    }));
    this.beats.push(...created);
    return created;
  }

  async applyRelationshipDeltas(worldId: string, deltas: RelationshipDeltaWrite[]): Promise<void> {
    for (const d of deltas) {
      let rel = this.relationships.find(
        (r) => r.worldId === worldId && r.fromDoubleId === d.fromDoubleId && r.toDoubleId === d.toDoubleId,
      );
      if (!rel) {
        rel = {
          id: randomUUID(),
          worldId,
          fromDoubleId: d.fromDoubleId,
          toDoubleId: d.toDoubleId,
          affinity: 0,
          type: 'neutral',
          updatedAt: iso(),
        };
        this.relationships.push(rel);
      }
      rel.affinity = clampAffinity(rel.affinity + d.delta);
      if (d.type) rel.type = d.type;
      rel.updatedAt = iso();
    }
  }

  async markAgendaOutcomes(outcomes: { agendaId: string; status: Agenda['status'] }[]): Promise<void> {
    for (const o of outcomes) {
      const a = this.agendas.find((x) => x.id === o.agendaId);
      if (a) a.status = o.status;
    }
  }

  async insertMarkets(worldId: string, episodeOpened: number, markets: NewMarket[]): Promise<Market[]> {
    const created = markets.map((m) => ({
      id: randomUUID(),
      worldId,
      episodeOpened,
      question: m.question,
      options: m.options,
      resolvesOnEpisode: m.resolvesOnEpisode,
      status: 'open' as const,
      winningOption: null,
      multiplier: m.multiplier,
      createdAt: iso(),
    }));
    this.markets.push(...created);
    return created;
  }

  async markPowerMovesApplied(ids: string[]): Promise<void> {
    for (const id of ids) {
      const pm = this.powerMoves.find((p) => p.id === id);
      if (pm) {
        pm.status = 'applied';
        pm.appliedAt = iso();
      }
    }
  }

  // ---- Db port: resolveBets ----
  async getMarketsResolvingOn(worldId: string, episode: number): Promise<Market[]> {
    return this.markets.filter(
      (m) => m.worldId === worldId && m.resolvesOnEpisode === episode && m.status === 'open',
    );
  }

  async resolveMarket(marketId: string, winningOption: string | null, void_?: boolean): Promise<void> {
    const m = this.markets.find((x) => x.id === marketId);
    if (m) {
      m.status = void_ ? 'void' : 'resolved';
      m.winningOption = winningOption;
    }
  }

  async getOpenBetsForMarket(marketId: string): Promise<Bet[]> {
    return this.bets.filter((b) => b.marketId === marketId && b.status === 'open');
  }

  async settleBet(betId: string, status: Bet['status'], resolvedEpisode: number): Promise<void> {
    const b = this.bets.find((x) => x.id === betId);
    if (b) {
      b.status = status;
      b.resolvedEpisode = resolvedEpisode;
    }
  }

  async adjustClout(userId: string, worldId: string, delta: number): Promise<void> {
    const row = this.clout.find((c) => c.userId === userId && c.worldId === worldId);
    if (row) row.balance += delta;
    else this.clout.push({ userId, worldId, balance: delta });
  }

  // ---- Db port: score ----
  async applyScoreDeltas(worldId: string, deltas: ScoreDeltaWrite[]): Promise<void> {
    for (const d of deltas) {
      let s = this.scores.find((x) => x.worldId === worldId && x.doubleId === d.doubleId);
      if (!s) {
        s = {
          id: randomUUID(),
          worldId,
          doubleId: d.doubleId,
          drama: 0,
          ships: 0,
          glowup: 0,
          villain: 0,
          updatedAt: iso(),
        };
        this.scores.push(s);
      }
      s.drama += d.drama;
      s.ships += d.ships;
      s.glowup += d.glowup;
      s.villain += d.villain;
      s.updatedAt = iso();
    }
  }

  async getSeasonScores(worldId: string): Promise<SeasonScore[]> {
    return this.scores.filter((s) => s.worldId === worldId);
  }

  async setSeasonStatus(worldId: string, status: World['seasonStatus']): Promise<void> {
    const w = this.worlds.find((x) => x.id === worldId);
    if (w) w.seasonStatus = status;
  }

  // ---- Db port: recaps ----
  async upsertRecap(episodeId: string, recap: NewRecap): Promise<void> {
    const existing = this.recaps.find((r) => r.episodeId === episodeId && r.userId === recap.userId);
    if (existing) {
      existing.narrative = recap.narrative;
      existing.highlights = recap.highlights;
      existing.gatedBeatIds = recap.gatedBeatIds;
    } else {
      this.recaps.push({ episodeId, ...recap });
    }
  }

  // ---- Db port: moderation ----
  async recordModerationEvents(events: ModerationEventWrite[]): Promise<void> {
    this.moderationEvents.push(...events);
  }
}

/** Build a small demo world matching the seed (5 doubles, neutral relationships). */
export function seedDemoWorld(db: InMemoryDb): { worldId: string; userIds: string[]; doubleIds: string[] } {
  const names = [
    ['Aria', 'aria'],
    ['Bex', 'bex'],
    ['Cory', 'cory'],
    ['Dru', 'dru'],
    ['Eli', 'eli'],
  ];
  const userIds: string[] = [];
  const doubleIds: string[] = [];
  const host = db.addUser();
  userIds.push(host);
  const world = db.addWorld({ name: 'The Group Chat', vibe: 'messy', createdBy: host });

  names.forEach(([displayName, handle], i) => {
    const userId = i === 0 ? host : db.addUser();
    if (i !== 0) userIds.push(userId);
    const dbl = db.addDouble({
      ownerUserId: userId,
      displayName: displayName!,
      handle: handle!,
      personaPrompt: `${displayName} brings ${['chaos', 'warmth', 'schemes', 'drama', 'vibes'][i]} to the group.`,
    });
    doubleIds.push(dbl.id);
    db.addMember(world.id, dbl.id);
    db.setClout(userId, world.id, 1000);
  });

  // Seed neutral directed relationships between all pairs.
  for (const from of doubleIds) {
    for (const to of doubleIds) {
      if (from === to) continue;
      db.relationships.push({
        id: randomUUID(),
        worldId: world.id,
        fromDoubleId: from,
        toDoubleId: to,
        affinity: 0,
        type: 'neutral',
        updatedAt: iso(),
      });
    }
  }

  return { worldId: world.id, userIds, doubleIds };
}
