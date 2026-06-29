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
 * DELETE /doubles/me — full account erasure (UK GDPR Art 17, brief §9). Purges
 * ALL of the caller's data (double, worlds membership, relationships, agendas,
 * scores, recaps, bets, power moves, clout, entitlements, reveal unlocks, push
 * tokens, invites) and deletes the Supabase Auth identity (the sign-in email).
 */
export async function DELETE(req: Request): Promise<Response> {
  try {
    const ctx = await requireVerified(req);
    await ctx.repo.deleteAccount(ctx.userId);
    return json({ deleted: true });
  } catch (err) {
    return handleError(err);
  }
}
