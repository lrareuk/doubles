import crypto from 'node:crypto';
import { createServiceClient, Repo } from '@doubles/db';
import { getEnv, getVeriff } from '@/lib/env';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

/**
 * POST /me/age-verify/webhook — Veriff decision webhook. This is the ONLY path
 * that may mark a user 18+. We verify the X-HMAC-SIGNATURE over the raw body
 * before trusting anything, then transition the user on a terminal decision.
 * Idempotent (keyed on the user); responds 200 fast (Veriff retries ~1 week).
 */
export async function POST(req: Request): Promise<Response> {
  try {
    const v = getVeriff();

    // Must hash the EXACT raw bytes — re-serialising a parsed object breaks it.
    const raw = await req.text();
    const provided = req.headers.get('x-hmac-signature') ?? '';
    const expected = crypto.createHmac('sha256', v.hmacSecret).update(raw).digest('hex');
    const valid =
      provided.length === expected.length &&
      crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(provided));
    if (!valid) return json({ error: 'bad signature' }, 401);

    const payload = JSON.parse(raw) as {
      verification?: {
        id?: string;
        status?: string;
        vendorData?: string;
        additionalVerifiedData?: { estimatedAge?: number };
      };
    };
    const ver = payload.verification ?? {};
    const userId = ver.vendorData;
    const ref = ver.id;
    // Nothing to attribute — acknowledge so Veriff stops retrying.
    if (!userId || !ref) return json({ ok: true });

    const repo = new Repo(createServiceClient(getEnv()));
    const estimatedAge = ver.additionalVerifiedData?.estimatedAge;
    // Pass only on a terminal 'approved'. If the integration also returns the
    // raw age, additionally require >= 18 (defence in depth).
    const passed = ver.status === 'approved' && (estimatedAge === undefined || estimatedAge >= 18);

    if (passed) {
      await repo.markAgeApproved(userId, ref);
    } else if (ver.status && ver.status !== 'review' && ver.status !== 'resubmission_requested') {
      // Terminal non-pass (declined / expired / abandoned). Interim states ignored.
      await repo.markAgeRejected(userId, ref);
    }

    return json({ ok: true });
  } catch (err) {
    return handleError(err);
  }
}
