import { authenticate } from '@/lib/auth';
import { getVeriff } from '@/lib/env';
import { json, handleError, HttpError } from '@/lib/responses';

export const runtime = 'nodejs';

/**
 * POST /me/age-verify/start — create a Veriff age-estimation session for the
 * caller and return its hosted URL. The user is bound via vendorData so the
 * decision webhook is attributable. No flag is set here; only the HMAC-verified
 * webhook may mark the user 18+.
 */
export async function POST(req: Request): Promise<Response> {
  try {
    const ctx = await authenticate(req);
    const v = getVeriff();

    const res = await fetch(`${v.baseUrl}/v1/sessions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-auth-client': v.apiKey },
      body: JSON.stringify({
        verification: {
          vendorData: ctx.userId,
          endUserId: ctx.userId,
          ...(v.callbackUrl ? { callback: v.callbackUrl } : {}),
        },
      }),
    });

    if (!res.ok) {
      const detail = await res.text().catch(() => '');
      throw new HttpError(`age session failed (${res.status})${detail ? `: ${detail}` : ''}`, 502, 'veriff_error');
    }

    const data = (await res.json()) as { verification?: { id?: string; url?: string } };
    const id = data.verification?.id;
    const url = data.verification?.url;
    if (!id || !url) throw new HttpError('age session malformed', 502, 'veriff_error');

    await ctx.repo.startAgeVerification(ctx.userId, id);
    return json({ url, id });
  } catch (err) {
    return handleError(err);
  }
}
