/**
 * Moderation seam (brief §6 stage 4, §9). Every generated beat and every
 * persona input passes through a Moderator before it is shown or saved. We ship
 * a MockModerator (keyword/rule checks) and leave a clear hook for a real
 * provider classifier. Do NOT overstate what this catches anywhere in copy.
 */
export interface ModerationResult {
  verdict: 'ok' | 'blocked';
  reason?: string;
}

export interface Moderator {
  /** Check a single piece of text. */
  check(text: string, subjectType: 'persona' | 'beat'): Promise<ModerationResult>;
}

/**
 * Deterministic rule-based moderator for the scaffold. This is a SCAFFOLD-LEVEL
 * check only — it is not a substitute for a real safety classifier.
 */
export class MockModerator implements Moderator {
  /** Minimal illustrative blocklist. A real impl would use a provider classifier. */
  private static readonly BLOCKED_PATTERNS: RegExp[] = [
    /\bkill\s+yourself\b/i,
    /\bdox(x)?\b/i,
    /\b(child|cp)\s*(porn|abuse)\b/i,
    // crude PII leak guard: bare-looking credit card / national insurance numbers
    /\b\d{13,19}\b/,
  ];

  async check(text: string, _subjectType: 'persona' | 'beat'): Promise<ModerationResult> {
    for (const pattern of MockModerator.BLOCKED_PATTERNS) {
      if (pattern.test(text)) {
        return { verdict: 'blocked', reason: `matched rule ${pattern.source}` };
      }
    }
    return { verdict: 'ok' };
  }
}
