import { describe, it, expect } from 'vitest';
import { randomUUID } from 'node:crypto';
import { runEpisode } from '../src/runEpisode.js';
import { MockAIClient } from '../src/ai/MockAIClient.js';
import { MockModerator } from '../src/moderation/Moderator.js';
import { MockNotifier } from '../src/notify/Notifier.js';
import { InMemoryDb, FixedClock, SilentLogger, seedDemoWorld } from '../src/testing/index.js';
import type { EngineDeps } from '../src/runEpisode.js';

function makeDeps(db: InMemoryDb): EngineDeps {
  return {
    db,
    ai: new MockAIClient(),
    moderator: new MockModerator(),
    notifier: new MockNotifier(),
    clock: new FixedClock(),
    logger: new SilentLogger(),
    config: { totalEpisodes: 14 },
  };
}

describe('runEpisode (integration, mock AI)', () => {
  it('runs an episode end-to-end for the seed world', async () => {
    const db = new InMemoryDb();
    const { worldId, userIds } = seedDemoWorld(db);

    const result = await runEpisode(makeDeps(db), worldId);

    expect(result.status).toBe('published');
    expect(result.episodeNumber).toBe(1);
    expect(result.beatsPublished).toBeGreaterThan(0);

    // Episode published and world advanced.
    const world = await db.getWorld(worldId);
    expect(world?.currentEpisode).toBe(1);
    const ep = await db.getEpisodeByNumber(worldId, 1);
    expect(ep?.status).toBe('published');
    expect(ep?.headline).toBeTruthy();

    // A recap per user.
    expect(db.recaps.length).toBe(userIds.length);

    // Scores were written.
    expect((await db.getSeasonScores(worldId)).length).toBeGreaterThan(0);

    // A market was proposed for a future episode.
    expect(db.markets.some((m) => m.resolvesOnEpisode > 1)).toBe(true);
  });

  it('is idempotent — re-running a published episode is a no-op', async () => {
    const db = new InMemoryDb();
    const { worldId } = seedDemoWorld(db);

    await runEpisode(makeDeps(db), worldId);
    // Force the world back so the same number would be attempted again.
    const world = await db.getWorld(worldId);
    world!.currentEpisode = 0;

    const second = await runEpisode(makeDeps(db), worldId);
    expect(second.status).toBe('noop');
  });

  it('applies a queued power move and consumes it', async () => {
    const db = new InMemoryDb();
    const { worldId, userIds, doubleIds } = seedDemoWorld(db);

    const pm = {
      id: randomUUID(),
      worldId,
      userId: userIds[0]!,
      type: 'sabotage' as const,
      targetDoubleId: doubleIds[1]!,
      payload: {},
      status: 'queued' as const,
      applyOnEpisode: 1,
      createdAt: new Date().toISOString(),
      appliedAt: null,
    };
    db.powerMoves.push(pm);

    await runEpisode(makeDeps(db), worldId);

    expect(db.powerMoves.find((p) => p.id === pm.id)?.status).toBe('applied');
    // Sabotage lowers the owner→target affinity below zero.
    const rel = db.relationships.find(
      (r) => r.fromDoubleId === doubleIds[0] && r.toDoubleId === doubleIds[1],
    );
    expect(rel!.affinity).toBeLessThan(0);
  });

  it('resolves a due market and pays the winner', async () => {
    const db = new InMemoryDb();
    const { worldId, userIds } = seedDemoWorld(db);

    const market = {
      id: randomUUID(),
      worldId,
      episodeOpened: 0,
      question: 'Will chaos erupt?',
      options: [
        { key: 'yes', label: 'Yes' },
        { key: 'no', label: 'No' },
      ],
      resolvesOnEpisode: 1,
      status: 'open' as const,
      winningOption: null,
      multiplier: 2,
      createdAt: new Date().toISOString(),
    };
    db.markets.push(market);

    // The mock planner resolves episode 1 markets to options[1 % 2] = 'no'.
    const better = userIds[0]!;
    db.setClout(better, worldId, 1000);
    db.bets.push({
      id: randomUUID(),
      worldId,
      userId: better,
      marketId: market.id,
      optionKey: 'no',
      stakeClout: 100,
      status: 'open',
      resolvedEpisode: null,
      createdAt: new Date().toISOString(),
    });

    await runEpisode(makeDeps(db), worldId);

    const resolved = db.markets.find((m) => m.id === market.id);
    expect(resolved?.status).toBe('resolved');
    expect(resolved?.winningOption).toBe('no');

    const bet = db.bets[0]!;
    expect(bet.status).toBe('won');
    // Winner credited stake × 2 (stake was deducted at placement in the real flow).
    expect(db.clout.find((c) => c.userId === better)?.balance).toBe(1200);
  });

  it('blocks beats that fail moderation', async () => {
    const db = new InMemoryDb();
    const { worldId } = seedDemoWorld(db);

    // A moderator that blocks everything.
    const deps = makeDeps(db);
    deps.moderator = { check: async () => ({ verdict: 'blocked', reason: 'test' }) };

    const result = await runEpisode(deps, worldId);
    expect(result.status).toBe('published');
    expect(result.beatsPublished).toBe(0);
    expect(result.blockedBeats).toBeGreaterThan(0);
    expect(db.moderationEvents.every((e) => e.verdict === 'blocked')).toBe(true);
  });
});
