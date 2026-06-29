import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /worlds/:id/relationships — the directed relationship graph for the world. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const relationships = await ctx.repo.getRelationships(id);
    return json({ relationships });
  } catch (err) {
    return handleError(err);
  }
}
