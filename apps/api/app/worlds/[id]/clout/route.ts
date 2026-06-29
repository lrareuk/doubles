import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /worlds/:id/clout — the caller's clout balance in this world. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const balance = await ctx.repo.getClout(id, ctx.userId);
    return json({ balance });
  } catch (err) {
    return handleError(err);
  }
}
