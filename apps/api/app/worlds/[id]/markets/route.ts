import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /worlds/:id/markets — open markets. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const markets = await ctx.repo.getOpenMarkets(id);
    return json({ markets });
  } catch (err) {
    return handleError(err);
  }
}
