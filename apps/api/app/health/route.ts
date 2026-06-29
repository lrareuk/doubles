import { json } from '@/lib/responses';

export const runtime = 'nodejs';

/** GET /health — liveness check (no auth). */
export function GET(): Response {
  return json({ ok: true, service: 'doubles-api', aiProvider: process.env.AI_PROVIDER ?? 'mock' });
}
