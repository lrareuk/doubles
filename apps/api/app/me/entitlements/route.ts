import { authenticate } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /me/entitlements — the caller's active entitlements. */
export async function GET(req: Request): Promise<Response> {
  try {
    const ctx = await authenticate(req);
    const entitlements = await ctx.repo.getEntitlements(ctx.userId);
    return json({ entitlements });
  } catch (err) {
    return handleError(err);
  }
}
