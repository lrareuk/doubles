import { GAME, ENTITLEMENTS, type EntitlementSku } from '@doubles/shared';

/**
 * Pure game-logic rules (brief §7). No I/O, no AI — deterministic and unit
 * tested. The engine and API call these; they never duplicate the math.
 */

export function clampAffinity(value: number): number {
  return Math.max(GAME.AFFINITY_MIN, Math.min(GAME.AFFINITY_MAX, value));
}

// ---- betting -------------------------------------------------------------
export interface BetResolution {
  won: boolean;
  /** Net change to the user's clout balance (negative = forfeited stake). */
  delta: number;
  payout: number;
}

/**
 * Resolve a single bet against the winning option. Winners receive stake ×
 * multiplier (the stake was already deducted on placement, so the net credit is
 * the gross payout). Losers forfeit their stake (already deducted → delta 0
 * here). Returns the delta to APPLY now, assuming the stake was deducted at
 * placement time.
 */
export function resolveBet(
  stake: number,
  optionKey: string,
  winningOption: string,
  multiplier: number = GAME.DEFAULT_BET_MULTIPLIER,
): BetResolution {
  if (optionKey === winningOption) {
    const payout = Math.floor(stake * multiplier);
    return { won: true, delta: payout, payout };
  }
  return { won: false, delta: 0, payout: 0 };
}

/** Can a user afford to stake this much? */
export function canAffordBet(balance: number, stake: number): boolean {
  return stake > 0 && balance >= stake;
}

// ---- power moves ---------------------------------------------------------
/** Daily power-move allowance derived from active entitlements (brief §7/§10). */
export function dailyPowerMoveAllowance(activeSkus: EntitlementSku[]): number {
  const base = GAME.FREE_DAILY_POWER_MOVES;
  const hasSub = activeSkus.includes('sub_monthly');
  return hasSub ? GAME.SUB_DAILY_POWER_MOVES : base;
}

/** Has the user got a power move left today? */
export function canSpendPowerMove(usedToday: number, activeSkus: EntitlementSku[]): boolean {
  return usedToday < dailyPowerMoveAllowance(activeSkus);
}

// ---- entitlements / gating ----------------------------------------------
/** Concurrent active-world limit derived from entitlements (brief §10). */
export function concurrentWorldLimit(activeSkus: EntitlementSku[]): number {
  return activeSkus.includes('sub_monthly')
    ? ENTITLEMENTS.SUB_CONCURRENT_WORLDS
    : ENTITLEMENTS.FREE_CONCURRENT_WORLDS;
}

/**
 * Reveal access (brief §10): a gated beat is viewable if the user has an active
 * subscription OR a matching reveal_unlocks row.
 */
export function canViewGatedBeat(opts: {
  hasActiveSubscription: boolean;
  hasUnlockForBeat: boolean;
}): boolean {
  return opts.hasActiveSubscription || opts.hasUnlockForBeat;
}

// ---- season scoring ------------------------------------------------------
export interface ScoreTotals {
  drama: number;
  ships: number;
  glowup: number;
  villain: number;
}

export function addScores(a: ScoreTotals, b: Partial<ScoreTotals>): ScoreTotals {
  return {
    drama: a.drama + (b.drama ?? 0),
    ships: a.ships + (b.ships ?? 0),
    glowup: a.glowup + (b.glowup ?? 0),
    villain: a.villain + (b.villain ?? 0),
  };
}

export interface DoubleScore {
  doubleId: string;
  scores: ScoreTotals;
}

export interface SeasonAwards {
  villain: string | null;
  bestCouple: string | null;
  biggestGlowup: string | null;
  mostDrama: string | null;
}

/** Compute end-of-season awards from accumulated scores (brief §7). */
export function computeAwards(scores: DoubleScore[]): SeasonAwards {
  const winnerBy = (key: keyof ScoreTotals): string | null => {
    let best: DoubleScore | null = null;
    for (const s of scores) {
      if (s.scores[key] <= 0) continue;
      if (!best || s.scores[key] > best.scores[key]) best = s;
    }
    return best?.doubleId ?? null;
  };
  return {
    villain: winnerBy('villain'),
    bestCouple: winnerBy('ships'),
    biggestGlowup: winnerBy('glowup'),
    mostDrama: winnerBy('drama'),
  };
}

// ---- seasons -------------------------------------------------------------
/** Is the given episode the last of the season? */
export function isFinalEpisode(currentEpisode: number, totalEpisodes: number): boolean {
  return currentEpisode >= totalEpisodes;
}

/** Compute the season end timestamp from a start date + length. */
export function seasonEndsAt(start: Date, lengthDays: number = GAME.SEASON_LENGTH_DAYS): Date {
  return new Date(start.getTime() + lengthDays * 24 * 60 * 60 * 1000);
}
