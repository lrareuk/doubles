import type { EpisodePlan, GeneratedBeat, GeneratedRecap, PlannedBeat, TokenUsage } from '@doubles/shared';
import type { WorldContext, RecapInput } from '../context.js';

/**
 * The single seam between the engine and any LLM (brief §6). Two implementations:
 * MockAIClient (deterministic, no key, default) and ClaudeAIClient (real).
 * Selected by AI_PROVIDER. All methods return validated structured output plus
 * token usage so the engine can enforce its budget.
 */
export interface PlanResult {
  plan: EpisodePlan;
  usage: TokenUsage;
}

export interface BeatsResult {
  beats: GeneratedBeat[];
  usage: TokenUsage;
}

export interface RecapResult {
  recap: GeneratedRecap;
  usage: TokenUsage;
}

export interface AIClient {
  /** PLAN_EPISODE (Sonnet). One call; cast block is cached. */
  planEpisode(context: WorldContext): Promise<PlanResult>;

  /**
   * GENERATE_BEAT (Haiku), batched in the real client. `context` provides the
   * cached cast block shared across every beat generation.
   */
  generateBeats(beats: PlannedBeat[], context: WorldContext): Promise<BeatsResult>;

  /** WRITE_RECAP (Haiku). */
  writeRecap(input: RecapInput): Promise<RecapResult>;
}

/** Empty usage accumulator. */
export function zeroUsage(): TokenUsage {
  return { inputTokens: 0, outputTokens: 0, cachedInputTokens: 0, calls: 0 };
}

export function addUsage(a: TokenUsage, b: TokenUsage): TokenUsage {
  return {
    inputTokens: a.inputTokens + b.inputTokens,
    outputTokens: a.outputTokens + b.outputTokens,
    cachedInputTokens: a.cachedInputTokens + b.cachedInputTokens,
    calls: a.calls + b.calls,
  };
}
