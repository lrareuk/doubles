import { JoinWorldInput } from '@doubles/shared';
import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** POST /worlds/:id/join — join via token; seeds membership + neutral relationships. */
export async function POST(req: Request): Promise<Response> {
  try {
    const ctx = await requireVerified(req);
    const input = JoinWorldInput.parse(await req.json());
    const world = await ctx.repo.joinWorld(ctx.userId, input.token);
    return json({ world });
  } catch (err) {
    return handleError(err);
  }
}
