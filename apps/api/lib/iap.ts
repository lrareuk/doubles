import type { EntitlementSku } from '@doubles/shared';

/**
 * IAP validation seam (brief §10). Real Apple/Google receipt validation is
 * deferred; the mock grants the requested SKU in dev. Honest billing: a real
 * validator must verify the receipt with the store before granting.
 */
export interface IapValidationResult {
  valid: boolean;
  sku: EntitlementSku;
  source: 'subscription' | 'season_pass' | 'consumable';
  reason?: string;
}

export interface IapValidator {
  validate(input: {
    sku: EntitlementSku;
    receipt: string;
    platform: 'apple' | 'google';
  }): Promise<IapValidationResult>;
}

function sourceForSku(sku: EntitlementSku): IapValidationResult['source'] {
  if (sku === 'sub_monthly') return 'subscription';
  if (sku === 'season_pass') return 'season_pass';
  return 'consumable';
}

/** Dev-only: accepts any non-empty receipt and grants the SKU. */
export class MockIapValidator implements IapValidator {
  async validate(input: {
    sku: EntitlementSku;
    receipt: string;
    platform: 'apple' | 'google';
  }): Promise<IapValidationResult> {
    if (!input.receipt) {
      return { valid: false, sku: input.sku, source: sourceForSku(input.sku), reason: 'empty receipt' };
    }
    return { valid: true, sku: input.sku, source: sourceForSku(input.sku) };
  }
}
