import { PlaceBetInput } from '@doubles/shared';
import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /worlds/:id/bets — the caller's bets in this world (enriched for display). */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const bets = await ctx.repo.myBets(id, ctx.userId);
    return json({ bets });
  } catch (err) {
    return handleError(err);
  }
}

/** POST /worlds/:id/bets — stake clout on an open market option. */
export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const input = PlaceBetInput.parse(await req.json());
    const bet = await ctx.repo.placeBet(id, ctx.userId, input.marketId, input.optionKey, input.stakeClout);
    return json({ bet }, 201);
  } catch (err) {
    return handleError(err);
  }
}
