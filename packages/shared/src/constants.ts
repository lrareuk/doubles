/**
 * Tunable game + engine constants. Defaults come from the brief (sections 6–10).
 * Anything env-overridable in the engine reads these as the fallback.
 */

export const GAME = {
  /** Clout each user starts a season with, per world. */
  STARTING_CLOUT: 1000,
  /** Small daily login grant of clout. */
  DAILY_CLOUT_GRANT: 50,
  /** Default payout multiplier for a binary market. */
  DEFAULT_BET_MULTIPLIER: 2,
  /** Free power moves per user per world per day. */
  FREE_DAILY_POWER_MOVES: 2,
  /** Extra daily power moves granted by an active subscription. */
  SUB_DAILY_POWER_MOVES: 5,
  /** Affinity bounds. */
  AFFINITY_MIN: -100,
  AFFINITY_MAX: 100,
  /** Season length in days. */
  SEASON_LENGTH_DAYS: 14,
} as const;

export const ENGINE = {
  /** Max beats generated per episode before graceful degradation. */
  DEFAULT_BEAT_CAP: 12,
  /** Soft token budget per episode; planner trims beats if exceeded. */
  DEFAULT_TOKEN_BUDGET: 120_000,
  /** How many prior episode summaries to feed the planner. */
  RECENT_EPISODE_WINDOW: 3,
  /** Regenerate a blocked beat at most this many times. */
  MAX_BEAT_REGENERATIONS: 1,
} as const;

export const ENTITLEMENTS = {
  /** Concurrent active worlds allowed without a subscription. */
  FREE_CONCURRENT_WORLDS: 1,
  /** Concurrent active worlds allowed with an active subscription. */
  SUB_CONCURRENT_WORLDS: 10,
} as const;

/** Power-move effect magnitudes applied deterministically in the engine. */
export const POWER_MOVE = {
  /** Affinity delta a sabotage applies to the target pairing. */
  SABOTAGE_AFFINITY_DELTA: -25,
} as const;
