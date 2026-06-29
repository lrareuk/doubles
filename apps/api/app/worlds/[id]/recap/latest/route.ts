import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /worlds/:id/recap/latest — the caller's personalized recap. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const recap = await ctx.repo.getLatestRecap(id, ctx.userId);
    return json({ recap });
  } catch (err) {
    return handleError(err);
  }
}
