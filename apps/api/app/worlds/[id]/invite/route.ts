import { InviteInput } from '@doubles/shared';
import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** POST /worlds/:id/invite — create an invite token. */
export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const body = await req.json().catch(() => ({}));
    const input = InviteInput.parse(body ?? {});
    const token = await ctx.repo.createInvite(id, ctx.userId, input.expiresInHours);
    return json({ token });
  } catch (err) {
    return handleError(err);
  }
}
