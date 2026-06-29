import { UpsertDoubleInput } from '@doubles/shared';
import { MockModerator } from '@doubles/engine';
import { requireVerified } from '@/lib/auth';
import { json, handleError, HttpError } from '@/lib/responses';

export const runtime = 'nodejs';

const moderator = new MockModerator();

/**
 * POST /doubles — create or update the CALLER'S OWN double (brief §8/§9).
 * There is no path to author another user's double: the owner is always the
 * authenticated caller. Persona moderation runs before saving.
 */
export async function POST(req: Request): Promise<Response> {
  try {
    const ctx = await requireVerified(req);
    const input = UpsertDoubleInput.parse(await req.json());

    const verdict = await moderator.check(input.personaPrompt, 'persona');
    await ctx.repo.recordModeration('persona', ctx.userId, verdict.verdict, verdict.reason);
    if (verdict.verdict === 'blocked') {
      throw new HttpError('persona failed moderation', 422, 'persona_blocked');
    }

    const double = await ctx.repo.upsertMyDouble(ctx.userId, input, 'ok');
    return json({ double });
  } catch (err) {
    return handleError(err);
  }
}
