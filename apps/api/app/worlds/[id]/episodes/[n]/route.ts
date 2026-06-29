import { requireVerified } from '@/lib/auth';
import { json, handleError, HttpError } from '@/lib/responses';

export const runtime = 'nodejs';

/**
 * GET /worlds/:id/episodes/:n — episode beats. Reveal-gated beats are returned
 * locked (content null) unless the caller has access (brief §8/§10).
 */
export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string; n: string }> },
): Promise<Response> {
  try {
    const { id, n } = await params;
    const number = Number(n);
    if (!Number.isInteger(number)) throw new HttpError('bad episode number', 400);
    const ctx = await requireVerified(req);
    const view = await ctx.repo.getEpisodeView(id, number, ctx.userId);
    if (!view) throw new HttpError('episode not found', 404);
    return json(view);
  } catch (err) {
    return handleError(err);
  }
}
