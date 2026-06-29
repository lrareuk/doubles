import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/**
 * POST /reveals/:beatId/unlock — reveal a gated beat by consuming a subscription
 * right or a consumable. Returns ONLY real stored content (brief §9: never
 * fabricate content to drive purchases).
 */
export async function POST(
  req: Request,
  { params }: { params: Promise<{ beatId: string }> },
): Promise<Response> {
  try {
    const { beatId } = await params;
    const ctx = await requireVerified(req);
    const skus = await ctx.repo.activeSkus(ctx.userId);
    const source = skus.includes('sub_monthly') ? 'subscription' : 'consumable';
    const beat = await ctx.repo.unlockReveal(ctx.userId, beatId, source);
    return json({ beat });
  } catch (err) {
    return handleError(err);
  }
}
