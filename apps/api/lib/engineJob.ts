import { createServiceClient } from '@doubles/db';
import { SupabaseDb } from '@doubles/db';
import {
  createAIClient,
  runEpisode,
  MockModerator,
  MockNotifier,
  type RunEpisodeResult,
  type EngineDeps,
} from '@doubles/engine';
import { getEnv } from './env';

class SystemClock {
  now(): Date {
    return new Date();
  }
}

class ConsoleLogger {
  info(msg: string, meta?: Record<string, unknown>): void {
    console.log(`[engine] ${msg}`, meta ?? '');
  }
  warn(msg: string, meta?: Record<string, unknown>): void {
    console.warn(`[engine] ${msg}`, meta ?? '');
  }
  error(msg: string, meta?: Record<string, unknown>): void {
    console.error(`[engine] ${msg}`, meta ?? '');
  }
}

/** Build engine dependencies wired to Supabase + the env-selected AI provider. */
export function buildEngineDeps(): EngineDeps {
  const env = getEnv();
  const sb = createServiceClient(env);
  return {
    db: new SupabaseDb(sb),
    ai: createAIClient(env),
    moderator: new MockModerator(),
    notifier: new MockNotifier(new ConsoleLogger()),
    clock: new SystemClock(),
    logger: new ConsoleLogger(),
    config: {
      beatCap: env.DOUBLES_BEAT_CAP ? Number(env.DOUBLES_BEAT_CAP) : undefined,
      tokenBudget: env.DOUBLES_TOKEN_BUDGET ? Number(env.DOUBLES_TOKEN_BUDGET) : undefined,
    },
  };
}

export async function runEpisodeForWorld(worldId: string): Promise<RunEpisodeResult> {
  return runEpisode(buildEngineDeps(), worldId);
}
