import { describe, it, expect } from 'vitest';
import {
  clampAffinity,
  resolveBet,
  canAffordBet,
  dailyPowerMoveAllowance,
  canSpendPowerMove,
  concurrentWorldLimit,
  canViewGatedBeat,
  computeAwards,
  isFinalEpisode,
  addScores,
} from '../src/game/index.js';

describe('clampAffinity', () => {
  it('clamps to [-100, 100]', () => {
    expect(clampAffinity(150)).toBe(100);
    expect(clampAffinity(-150)).toBe(-100);
    expect(clampAffinity(42)).toBe(42);
  });
});

describe('resolveBet', () => {
  it('pays winners stake × multiplier', () => {
    const r = resolveBet(100, 'yes', 'yes', 2);
    expect(r.won).toBe(true);
    expect(r.payout).toBe(200);
    expect(r.delta).toBe(200);
  });
  it('forfeits losers (no positive delta)', () => {
    const r = resolveBet(100, 'no', 'yes', 2);
    expect(r.won).toBe(false);
    expect(r.delta).toBe(0);
  });
  it('uses the default multiplier when omitted', () => {
    expect(resolveBet(50, 'a', 'a').payout).toBe(100);
  });
});

describe('canAffordBet', () => {
  it('requires positive stake within balance', () => {
    expect(canAffordBet(1000, 500)).toBe(true);
    expect(canAffordBet(1000, 1001)).toBe(false);
    expect(canAffordBet(1000, 0)).toBe(false);
    expect(canAffordBet(1000, -5)).toBe(false);
  });
});

describe('power-move allowance', () => {
  it('free users get the base allowance', () => {
    expect(dailyPowerMoveAllowance([])).toBe(2);
  });
  it('subscribers get the larger allowance', () => {
    expect(dailyPowerMoveAllowance(['sub_monthly'])).toBe(5);
  });
  it('enforces the daily cap', () => {
    expect(canSpendPowerMove(1, [])).toBe(true);
    expect(canSpendPowerMove(2, [])).toBe(false);
    expect(canSpendPowerMove(2, ['sub_monthly'])).toBe(true);
  });
});

describe('entitlement gating', () => {
  it('limits concurrent worlds by subscription', () => {
    expect(concurrentWorldLimit([])).toBe(1);
    expect(concurrentWorldLimit(['sub_monthly'])).toBe(10);
  });
  it('gates reveal access on sub OR a matching unlock', () => {
    expect(canViewGatedBeat({ hasActiveSubscription: true, hasUnlockForBeat: false })).toBe(true);
    expect(canViewGatedBeat({ hasActiveSubscription: false, hasUnlockForBeat: true })).toBe(true);
    expect(canViewGatedBeat({ hasActiveSubscription: false, hasUnlockForBeat: false })).toBe(false);
  });
});

describe('season scoring', () => {
  it('accumulates score deltas', () => {
    const total = addScores({ drama: 1, ships: 0, glowup: 2, villain: 0 }, { drama: 3, villain: 1 });
    expect(total).toEqual({ drama: 4, ships: 0, glowup: 2, villain: 1 });
  });
  it('computes awards from the leaders', () => {
    const awards = computeAwards([
      { doubleId: 'a', scores: { drama: 5, ships: 1, glowup: 0, villain: 9 } },
      { doubleId: 'b', scores: { drama: 2, ships: 4, glowup: 3, villain: 0 } },
    ]);
    expect(awards.villain).toBe('a');
    expect(awards.mostDrama).toBe('a');
    expect(awards.bestCouple).toBe('b');
    expect(awards.biggestGlowup).toBe('b');
  });
  it('returns null awards when no one scored a category', () => {
    const awards = computeAwards([{ doubleId: 'a', scores: { drama: 0, ships: 0, glowup: 0, villain: 0 } }]);
    expect(awards.villain).toBeNull();
  });
});

describe('isFinalEpisode', () => {
  it('detects the last episode', () => {
    expect(isFinalEpisode(14, 14)).toBe(true);
    expect(isFinalEpisode(13, 14)).toBe(false);
  });
});
