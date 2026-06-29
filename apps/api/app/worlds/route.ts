import { CreateWorldInput } from '@doubles/shared';
import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** POST /worlds — create a season. The creator's double joins as host. */
export async function POST(req: Request): Promise<Response> {
  try {
    const ctx = await requireVerified(req);
    const input = CreateWorldInput.parse(await req.json());
    const world = await ctx.repo.createWorld(ctx.userId, input);
    return json({ world }, 201);
  } catch (err) {
    return handleError(err);
  }
}
