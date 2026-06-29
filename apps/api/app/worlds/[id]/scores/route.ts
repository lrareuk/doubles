import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /worlds/:id/scores — season standings (drama, ships, glow-up, villain). */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const standings = await ctx.repo.getStandings(id);
    return json({ standings });
  } catch (err) {
    return handleError(err);
  }
}
