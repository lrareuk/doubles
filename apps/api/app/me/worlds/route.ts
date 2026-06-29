import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /me/worlds — the worlds the caller's double belongs to. */
export async function GET(req: Request): Promise<Response> {
  try {
    const ctx = await requireVerified(req);
    const worlds = await ctx.repo.myWorlds(ctx.userId);
    return json({ worlds });
  } catch (err) {
    return handleError(err);
  }
}
