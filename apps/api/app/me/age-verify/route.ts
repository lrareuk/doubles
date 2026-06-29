import { authenticate } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/**
 * POST /me/age-verify — record adult age assurance.
 * The vendor is stubbed (brief §8): we just set the flag. The seam to integrate
 * a real age-assurance vendor lives here.
 */
export async function POST(req: Request): Promise<Response> {
  try {
    const ctx = await authenticate(req);
    await ctx.repo.ageVerify(ctx.userId);
    return json({ ageVerified: true });
  } catch (err) {
    return handleError(err);
  }
}
