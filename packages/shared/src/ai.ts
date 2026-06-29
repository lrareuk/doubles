import { z } from 'zod';
import * as E from './enums.js';

/**
 * Structured I/O contracts for the AI prompt modules. The engine NEVER trusts
 * raw model output — everything is parsed against these schemas and rejected on
 * mismatch (brief §13: "parse and validate"). Kept here in shared so the prompt
 * modules, the mock client and the real Claude client all agree.
 */

/** A single planned beat the planner emits (content is generated later). */
export const PlannedBeat = z.object({
  /** Stable id within the plan so generated content can be matched back. */
  ref: z.string(),
  kind: E.BeatKind,
  /** Display handles or double ids the planner wants in this beat. */
  participants: z.array(z.string()).min(1),
  /** One-line intent the GENERATE_BEAT prompt expands into content. */
  intent: z.string().min(1),
  visibility: E.BeatVisibility.default('public'),
  /** Optional: this beat pays off a queued power move (by id). */
  fromPowerMoveId: z.string().uuid().optional(),
  /** Whether this is a high-leverage beat worth the Sonnet model. */
  highLeverage: z.boolean().default(false),
});
export type PlannedBeat = z.infer<typeof PlannedBeat>;

export const AgendaOutcome = z.object({
  agendaId: z.string().uuid(),
  status: z.enum(['succeeded', 'failed', 'in_progress']),
});
export type AgendaOutcome = z.infer<typeof AgendaOutcome>;

export const RelationshipDelta = z.object({
  fromDoubleId: z.string().uuid(),
  toDoubleId: z.string().uuid(),
  /** Signed change applied to affinity; engine clamps to [-100, 100]. */
  delta: z.number().int().min(-100).max(100),
  /** Optional new relationship label. */
  type: E.RelationshipType.optional(),
});
export type RelationshipDelta = z.infer<typeof RelationshipDelta>;

export const ScoreDelta = z.object({
  doubleId: z.string().uuid(),
  drama: z.number().int().default(0),
  ships: z.number().int().default(0),
  glowup: z.number().int().default(0),
  villain: z.number().int().default(0),
});
export type ScoreDelta = z.infer<typeof ScoreDelta>;

/**
 * A proposed market with a MACHINE-CHECKABLE resolution tag, so resolveBets can
 * settle it deterministically with no AI (brief §6 stage 6 + §8).
 */
export const ProposedMarket = z.object({
  question: z.string(),
  options: z.array(z.object({ key: z.string(), label: z.string() })).min(2),
  resolvesOnEpisode: z.number().int().nonnegative(),
  multiplier: z.number().positive().default(2),
  /**
   * How resolveBets decides the winner without calling the AI. The planner
   * emits the resolution at plan time for the episode that will resolve it.
   */
  resolution: z
    .object({
      /** Which option key wins if the tagged condition holds. */
      winningOption: z.string(),
    })
    .nullable()
    .default(null),
});
export type ProposedMarket = z.infer<typeof ProposedMarket>;

/** Output of PLAN_EPISODE (Sonnet). The single most important AI contract. */
export const EpisodePlan = z.object({
  /** A short headline summary of the episode for recaps/feeds. */
  headline: z.string(),
  beats: z.array(PlannedBeat),
  agendaOutcomes: z.array(AgendaOutcome).default([]),
  relationshipDeltas: z.array(RelationshipDelta).default([]),
  scoreDeltas: z.array(ScoreDelta).default([]),
  /** Power-move ids the planner consumed this episode (must be marked applied). */
  consumedPowerMoveIds: z.array(z.string().uuid()).default([]),
  /** Markets to open for a future episode. */
  proposedMarkets: z.array(ProposedMarket).default([]),
  /** Resolutions for markets resolving THIS episode (machine-checkable). */
  marketResolutions: z
    .array(z.object({ marketId: z.string().uuid(), winningOption: z.string() }))
    .default([]),
});
export type EpisodePlan = z.infer<typeof EpisodePlan>;

/** Output of GENERATE_BEAT (Haiku). */
export const GeneratedBeat = z.object({
  ref: z.string(),
  content: z.string().min(1),
});
export type GeneratedBeat = z.infer<typeof GeneratedBeat>;

/** Output of WRITE_RECAP (Haiku). */
export const GeneratedRecap = z.object({
  narrative: z.string().min(1),
  highlights: z.array(z.string()).default([]),
});
export type GeneratedRecap = z.infer<typeof GeneratedRecap>;

/** Token accounting attached to an episode. */
export const TokenUsage = z.object({
  inputTokens: z.number().int().nonnegative().default(0),
  outputTokens: z.number().int().nonnegative().default(0),
  cachedInputTokens: z.number().int().nonnegative().default(0),
  calls: z.number().int().nonnegative().default(0),
});
export type TokenUsage = z.infer<typeof TokenUsage>;
