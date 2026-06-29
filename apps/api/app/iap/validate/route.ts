import { IapValidateInput } from '@doubles/shared';
import { authenticate } from '@/lib/auth';
import { json, handleError, HttpError } from '@/lib/responses';
import { MockIapValidator } from '@/lib/iap';

export const runtime = 'nodejs';

const validator = new MockIapValidator();

/**
 * POST /iap/validate — validate a store receipt and grant an entitlement.
 * Real Apple/Google validation is stubbed behind the IapValidator interface
 * (brief §10). No real payments are processed.
 */
export async function POST(req: Request): Promise<Response> {
  try {
    const ctx = await authenticate(req);
    const input = IapValidateInput.parse(await req.json());
    const result = await validator.validate(input);
    if (!result.valid) throw new HttpError(result.reason ?? 'invalid receipt', 402, 'invalid_receipt');
    await ctx.repo.grantEntitlement(ctx.userId, result.sku, result.source);
    return json({ granted: result.sku });
  } catch (err) {
    return handleError(err);
  }
}
