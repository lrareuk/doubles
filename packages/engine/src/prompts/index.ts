import type { WorldContext, RecapInput } from '../context.js';
import type { PlannedBeat } from '@doubles/shared';

/**
 * Named, versioned prompt modules with explicit input/output JSON contracts
 * (brief §6). Each exports a system block (stable → cacheable) and a user block
 * (volatile). The engine validates every output against the zod schemas in
 * @doubles/shared before trusting it.
 */

export const PROMPT_VERSION = 'v1';

/** The stable cast + world block. The real client marks this for prompt caching. */
export function castBlock(ctx: WorldContext): string {
  const cast = ctx.cast
    .map(
      (c) =>
        `- @${c.handle} (${c.displayName}) [id:${c.doubleId}]\n    persona: ${c.persona}\n    traits: ${JSON.stringify(c.traits)}`,
    )
    .join('\n');
  const rels = ctx.relationships
    .map((r) => `  @${r.fromHandle} → @${r.toHandle}: ${r.type} (${r.affinity})`)
    .join('\n');
  return [
    `WORLD: "${ctx.worldName}" — vibe: ${ctx.vibe}, season ${ctx.seasonNumber}.`,
    `This is an autonomous social sim. The doubles below are self-authored characters of real people.`,
    `Stay strictly in character. Keep it spicy but never produce disallowed content.`,
    ``,
    `CAST:`,
    cast,
    ``,
    `RELATIONSHIPS (directed, affinity -100..100):`,
    rels || '  (none yet — seed neutral)',
  ].join('\n');
}

// ---- PLAN_EPISODE (Sonnet) ----------------------------------------------
export const PLAN_EPISODE = {
  name: 'PLAN_EPISODE',
  model: 'plan' as const,
  system(ctx: WorldContext): string {
    return [
      `You are the show-runner for "Doubles", planning ONE nightly episode.`,
      `Output a STRICT JSON object matching the EpisodePlan schema. No prose, no markdown.`,
      ``,
      castBlock(ctx),
    ].join('\n');
  },
  user(ctx: WorldContext): string {
    const agendas = ctx.agendas.length
      ? ctx.agendas.map((a) => `  - [${a.agendaId}] @${a.handle}: ${a.intent}`).join('\n')
      : '  (none)';
    const powerMoves = ctx.queuedPowerMoves.length
      ? ctx.queuedPowerMoves
          .map(
            (p) =>
              `  - [${p.id}] ${p.type} by @${p.ownerHandle ?? '?'}${p.targetHandle ? ` targeting @${p.targetHandle}` : ''} payload:${JSON.stringify(p.payload)}`,
          )
          .join('\n')
      : '  (none)';
    const recent = ctx.recentEpisodeSummaries.length
      ? ctx.recentEpisodeSummaries.map((e) => `  - Ep ${e.number}: ${e.headline}`).join('\n')
      : '  (this is an early episode)';
    const markets = ctx.marketsResolvingNow.length
      ? ctx.marketsResolvingNow
          .map(
            (m) =>
              `  - [${m.id}] ${m.question} options:[${m.options.map((o) => o.key).join(',')}]`,
          )
          .join('\n')
      : '  (none resolving)';

    return [
      `Plan episode ${ctx.episodeNumber}.`,
      ``,
      `AGENDAS to pay off or fail:`,
      agendas,
      ``,
      `QUEUED POWER MOVES (you MUST honour each, list its id in consumedPowerMoveIds):`,
      powerMoves,
      ``,
      `RECENT EPISODES:`,
      recent,
      ``,
      `MARKETS RESOLVING THIS EPISODE (pick a winningOption for each in marketResolutions):`,
      markets,
      ``,
      `CONSTRAINTS:`,
      `- Emit at most ${ctx.beatCap} beats.`,
      `- Each beat: { ref, kind(post|dm|scene|twist|ship), participants[handles], intent, visibility(public|reveal_gated), highLeverage }.`,
      `- relationshipDeltas use double ids, delta in -100..100.`,
      `- scoreDeltas: per double { doubleId, drama, ships, glowup, villain }.`,
      `- proposedMarkets resolve on a FUTURE episode.`,
      `Return ONLY the JSON object.`,
    ].join('\n');
  },
};

// ---- GENERATE_BEAT (Haiku) ----------------------------------------------
export const GENERATE_BEAT = {
  name: 'GENERATE_BEAT',
  model: 'beat' as const,
  system(ctx: WorldContext): string {
    return [
      `You write a single in-character beat for "Doubles". Output STRICT JSON: { "ref": string, "content": string }.`,
      `Voice each double per their persona. Keep beats short (1-3 sentences). No markdown.`,
      ``,
      castBlock(ctx),
    ].join('\n');
  },
  user(beat: PlannedBeat): string {
    return [
      `Write beat ref="${beat.ref}".`,
      `kind: ${beat.kind}`,
      `participants: ${beat.participants.join(', ')}`,
      `intent: ${beat.intent}`,
      `Return ONLY: { "ref": "${beat.ref}", "content": "..." }`,
    ].join('\n');
  },
};

// ---- WRITE_RECAP (Haiku) ------------------------------------------------
export const WRITE_RECAP = {
  name: 'WRITE_RECAP',
  model: 'recap' as const,
  system(): string {
    return [
      `You write a short, punchy morning recap for one player of "Doubles".`,
      `Second person ("your double"). Output STRICT JSON: { "narrative": string, "highlights": string[] }.`,
      `Do NOT reveal content marked as gated. No markdown.`,
    ].join('\n');
  },
  user(input: RecapInput): string {
    const beats = input.relevantBeats.map((b) => `  [${b.kind}] ${b.content}`).join('\n');
    return [
      `Episode ${input.episodeNumber} of "${input.worldName}" for @${input.userHandle}.`,
      `Headline: ${input.headline}`,
      ``,
      `Beats involving your double:`,
      beats || '  (none — keep it brief)',
      ``,
      `World headlines: ${input.worldHeadlines.join(' | ')}`,
      `Return ONLY the JSON object.`,
    ].join('\n');
  },
};
