import { createServiceClient, getUserIdFromToken, Repo } from '@doubles/db';
import { getEnv } from './env';
import { HttpError } from './responses';

/** A resolved, authenticated request context shared by route handlers. */
export interface Ctx {
  userId: string;
  repo: Repo;
}

function bearer(req: Request): string {
  const header = req.headers.get('authorization') ?? '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) throw new HttpError('missing bearer token', 401, 'no_token');
  return match[1]!;
}

/** Resolve the caller's user id from their Supabase JWT and build a Repo. */
export async function authenticate(req: Request): Promise<Ctx> {
  const env = getEnv();
  const token = bearer(req);
  const userId = await getUserIdFromToken(env, token);
  if (!userId) throw new HttpError('invalid token', 401, 'bad_token');
  const repo = new Repo(createServiceClient(env));
  await repo.ensureUser(userId);
  return { userId, repo };
}

/**
 * Authenticate AND require age verification — the gate on every social route
 * (brief §9). No path exists for under-18 use.
 */
export async function requireVerified(req: Request): Promise<Ctx> {
  const ctx = await authenticate(req);
  const verified = await ctx.repo.isAgeVerified(ctx.userId);
  if (!verified) throw new HttpError('age verification required', 403, 'age_unverified');
  return ctx;
}
