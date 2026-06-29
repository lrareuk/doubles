import { PowerMoveInput } from '@doubles/shared';
import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/**
 * POST /worlds/:id/power-moves — spend a power move (the metered, monetized verb).
 * Enforces the daily allowance derived from entitlements (brief §7/§10).
 */
export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const input = PowerMoveInput.parse(await req.json());
    await ctx.repo.spendPowerMove(
      id,
      ctx.userId,
      input.type,
      input.targetDoubleId ?? null,
      input.payload ?? {},
    );
    const remaining = await ctx.repo.powerMovesRemaining(id, ctx.userId);
    return json({ ok: true, powerMovesRemaining: remaining });
  } catch (err) {
    return handleError(err);
  }
}
