import { getEnv } from '@/lib/env';
import { runEpisodeForWorld } from '@/lib/engineJob';
import { json, handleError, HttpError } from '@/lib/responses';

export const runtime = 'nodejs';
// 60s = Vercel Hobby ceiling. The job finishes in <1s on mock AI and well within
// 60s on synchronous Claude (Haiku). Only the Batch API (DOUBLES_USE_BATCH=true)
// would exceed this — keep that off on Hobby (use synchronous Claude or mock).
export const maxDuration = 60;

/**
 * POST /jobs/run-episode/:worldId — run the nightly engine for a world.
 * Protected by a shared job secret (Bearer) so only Supabase Cron / ops can
 * trigger it (brief §8). Idempotent: re-running a published episode is a no-op.
 */
export async function POST(
  req: Request,
  { params }: { params: Promise<{ worldId: string }> },
): Promise<Response> {
  try {
    const env = getEnv();
    const auth = req.headers.get('authorization') ?? '';
    const token = auth.replace(/^Bearer\s+/i, '');
    if (!token || token !== env.JOB_SECRET) {
      throw new HttpError('unauthorized', 401, 'bad_job_secret');
    }
    const { worldId } = await params;
    const result = await runEpisodeForWorld(worldId);
    const status = result.status === 'failed' ? 500 : 200;
    return json(result, status);
  } catch (err) {
    return handleError(err);
  }
}
