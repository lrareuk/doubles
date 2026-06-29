import { requireVerified } from '@/lib/auth';
import { json, handleError, HttpError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /worlds/:id — world state, standings, my double, season status. */
export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const world = await ctx.repo.getWorld(id);
    if (!world) throw new HttpError('world not found', 404);

    const [myDouble, members, standings, cloutBalance, powerMovesRemaining] = await Promise.all([
      ctx.repo.getMyDouble(ctx.userId),
      ctx.repo.getMembers(id),
      ctx.repo.getStandings(id),
      ctx.repo.getClout(id, ctx.userId),
      ctx.repo.powerMovesRemaining(id, ctx.userId),
    ]);

    return json({
      world,
      myDouble,
      members,
      standings,
      cloutBalance,
      powerMovesRemaining,
    });
  } catch (err) {
    return handleError(err);
  }
}
