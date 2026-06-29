import { authenticate } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/**
 * GET /me/age-verify — read the caller's age-assurance status. The client polls
 * this after completing the Veriff flow until `ageVerified` flips true.
 *
 * NOTE: there is deliberately NO endpoint that lets the client *assert* its own
 * age. The flag is set only by the HMAC-verified Veriff decision webhook
 * (see ./webhook/route.ts). Self-declaration is not "highly effective age
 * assurance" under the Online Safety Act.
 */
export async function GET(req: Request): Promise<Response> {
  try {
    const ctx = await authenticate(req);
    const ageVerified = await ctx.repo.isAgeVerified(ctx.userId);
    return json({ ageVerified });
  } catch (err) {
    return handleError(err);
  }
}
