import type { EpisodePlan, PlannedBeat, GeneratedBeat } from '@doubles/shared';
import type { WorldContext, RecapInput } from '../context.js';
import type { AIClient, PlanResult, BeatsResult, RecapResult } from './AIClient.js';

/**
 * Deterministic, network-free AI client (brief §6). This is the DEFAULT so the
 * entire nightly loop runs in CI and locally with no Anthropic key. Output is a
 * function of the context only — same world state in, same episode out.
 */
export class MockAIClient implements AIClient {
  async planEpisode(context: WorldContext): Promise<PlanResult> {
    const cast = context.cast;
    const beats: PlannedBeat[] = [];

    const pick = (i: number) => cast[((i % cast.length) + cast.length) % cast.length]!;

    // Power moves first — every queued move is honoured and consumed.
    const consumedPowerMoveIds: string[] = [];
    const relationshipDeltas: EpisodePlan['relationshipDeltas'] = [];
    for (const pm of context.queuedPowerMoves) {
      consumedPowerMoveIds.push(pm.id);
      if (pm.type === 'sabotage' && pm.ownerDoubleId && pm.targetDoubleId) {
        relationshipDeltas.push({
          fromDoubleId: pm.ownerDoubleId,
          toDoubleId: pm.targetDoubleId,
          delta: -25,
          type: 'rival',
        });
      }
      if (pm.type === 'force_encounter' && pm.ownerDoubleId && pm.targetDoubleId) {
        beats.push({
          ref: `pm-${pm.id}`,
          kind: 'scene',
          participants: [
            handleFor(context, pm.ownerDoubleId),
            handleFor(context, pm.targetDoubleId),
          ],
          intent: `A forced encounter between ${handleFor(context, pm.ownerDoubleId)} and ${handleFor(context, pm.targetDoubleId)}.`,
          visibility: 'public',
          fromPowerMoveId: pm.id,
          highLeverage: true,
        });
      }
      if (pm.type === 'rumour' && pm.ownerHandle) {
        beats.push({
          ref: `pm-${pm.id}`,
          kind: 'post',
          participants: [pm.ownerHandle],
          intent: `A rumour starts spreading, planted by ${pm.ownerHandle}.`,
          visibility: 'public',
          fromPowerMoveId: pm.id,
          highLeverage: false,
        });
      }
    }

    // One opening post per cast member up to the cap.
    for (let i = 0; i < cast.length && beats.length < context.beatCap - 2; i++) {
      const c = cast[i]!;
      beats.push({
        ref: `post-${c.doubleId}`,
        kind: 'post',
        participants: [c.handle],
        intent: `${c.handle} posts something in character about the ${context.vibe} energy.`,
        visibility: 'public',
        highLeverage: false,
      });
    }

    // A ship and a twist if there's room.
    if (cast.length >= 2 && beats.length < context.beatCap) {
      const a = pick(context.episodeNumber);
      const b = pick(context.episodeNumber + 1);
      if (a.doubleId !== b.doubleId) {
        beats.push({
          ref: 'ship-1',
          kind: 'ship',
          participants: [a.handle, b.handle],
          intent: `Sparks between ${a.handle} and ${b.handle}.`,
          visibility: 'public',
          highLeverage: true,
        });
        relationshipDeltas.push({
          fromDoubleId: a.doubleId,
          toDoubleId: b.doubleId,
          delta: 15,
          type: 'crush',
        });
      }
    }
    if (beats.length < context.beatCap) {
      const v = pick(context.episodeNumber + 2);
      beats.push({
        ref: 'twist-1',
        kind: 'twist',
        participants: [v.handle],
        intent: `A twist: ${v.handle} reveals a secret. (Some of it stays private.)`,
        visibility: 'reveal_gated',
        highLeverage: true,
      });
    }

    // Mark every pending agenda — alternate success/in-progress deterministically.
    const agendaOutcomes = context.agendas.map((a, i) => ({
      agendaId: a.agendaId,
      status: (i % 2 === 0 ? 'succeeded' : 'in_progress') as 'succeeded' | 'in_progress',
    }));

    // Scores: drama for the twist owner, ships for the shipped pair, villain for sabotage.
    const scoreDeltas: EpisodePlan['scoreDeltas'] = cast.map((c, i) => ({
      doubleId: c.doubleId,
      drama: i === 0 ? 2 : 1,
      ships: 0,
      glowup: i % 3 === 0 ? 1 : 0,
      villain: context.queuedPowerMoves.some((p) => p.ownerDoubleId === c.doubleId) ? 2 : 0,
    }));

    // Resolve any market due this episode — pick the first option deterministically.
    const marketResolutions = context.marketsResolvingNow.map((m) => ({
      marketId: m.id,
      winningOption: m.options[context.episodeNumber % m.options.length]?.key ?? m.options[0]!.key,
    }));

    // Propose one market for two episodes out.
    const proposedMarkets: EpisodePlan['proposedMarkets'] =
      cast.length >= 2
        ? [
            {
              question: `Will ${pick(context.episodeNumber).handle} and ${pick(context.episodeNumber + 1).handle} still be a thing next episode?`,
              options: [
                { key: 'yes', label: 'Yes, endgame' },
                { key: 'no', label: 'No, it falls apart' },
              ],
              resolvesOnEpisode: context.episodeNumber + 2,
              multiplier: 2,
              resolution: null,
            },
          ]
        : [];

    const plan: EpisodePlan = {
      headline: `Episode ${context.episodeNumber}: ${context.vibe.replace('_', ' ')} in ${context.worldName}`,
      beats: beats.slice(0, context.beatCap),
      agendaOutcomes,
      relationshipDeltas,
      scoreDeltas,
      consumedPowerMoveIds,
      proposedMarkets,
      marketResolutions,
    };

    return {
      plan,
      usage: { inputTokens: 0, outputTokens: 0, cachedInputTokens: 0, calls: 1 },
    };
  }

  async generateBeats(beats: PlannedBeat[], context: WorldContext): Promise<BeatsResult> {
    const generated: GeneratedBeat[] = beats.map((b) => ({
      ref: b.ref,
      content: renderBeat(b, context),
    }));
    return {
      beats: generated,
      usage: { inputTokens: 0, outputTokens: 0, cachedInputTokens: 0, calls: beats.length },
    };
  }

  async writeRecap(input: RecapInput): Promise<RecapResult> {
    const lines = input.relevantBeats.slice(0, 3).map((b) => `• ${b.content}`);
    const narrative =
      `Episode ${input.episodeNumber} of ${input.worldName}. ${input.headline}\n\n` +
      (lines.length
        ? `Your double was in the mix:\n${lines.join('\n')}`
        : `Your double kept a low profile this episode.`);
    return {
      recap: {
        narrative,
        highlights: input.worldHeadlines.slice(0, 3),
      },
      usage: { inputTokens: 0, outputTokens: 0, cachedInputTokens: 0, calls: 1 },
    };
  }
}

function handleFor(context: WorldContext, doubleId: string): string {
  return context.cast.find((c) => c.doubleId === doubleId)?.handle ?? 'someone';
}

function renderBeat(b: PlannedBeat, context: WorldContext): string {
  const who = b.participants.join(' & ');
  switch (b.kind) {
    case 'post':
      return `@${b.participants[0]}: ${b.intent}`;
    case 'dm':
      return `[DM ${who}] ${b.intent}`;
    case 'scene':
      return `*Scene — ${who}*: ${b.intent}`;
    case 'twist':
      return `PLOT TWIST in ${context.worldName}: ${b.intent}`;
    case 'ship':
      return `💞 ${who}: ${b.intent}`;
    default:
      return b.intent;
  }
}
