import { SetAgendaInput } from '@doubles/shared';
import { requireVerified } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** POST /worlds/:id/agenda — set my double's intent for the next episode. */
export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }): Promise<Response> {
  try {
    const { id } = await params;
    const ctx = await requireVerified(req);
    const input = SetAgendaInput.parse(await req.json());
    await ctx.repo.setAgenda(id, ctx.userId, input.intentText);
    return json({ ok: true });
  } catch (err) {
    return handleError(err);
  }
}
