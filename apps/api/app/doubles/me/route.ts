import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /doubles/me — the caller's own double. */
export async function GET(req: Request): Promise<Response> {
  try {
    const ctx = await requireVerified(req);
    const double = await ctx.repo.getMyDouble(ctx.userId);
    return json({ double });
  } catch (err) {
    return handleError(err);
  }
}

/**
 * DELETE /doubles/me — instant removal (brief §9). Hard-deletes the caller's
 * double and purges derived content; cascades remove memberships, relationships,
 * agendas, scores and queued power moves.
 */
export async function DELETE(req: Request): Promise<Response> {
  try {
    const ctx = await requireVerified(req);
    await ctx.repo.deleteMyDoubleAndPurge(ctx.userId);
    return json({ deleted: true });
  } catch (err) {
    return handleError(err);
  }
}
