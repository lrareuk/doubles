import { z } from 'zod';
import { authenticate } from '@/lib/auth';
import { json, handleError } from '@/lib/responses';

export const runtime = 'nodejs';

const Input = z.object({
  token: z.string().min(1),
  platform: z.enum(['ios', 'android']).default('ios'),
});

/** POST /me/push-token — register a device for the morning-recap push. */
export async function POST(req: Request): Promise<Response> {
  try {
    const ctx = await authenticate(req);
    const input = Input.parse(await req.json());
    await ctx.repo.savePushToken(ctx.userId, input.token, input.platform);
    return json({ ok: true });
  } catch (err) {
    return handleError(err);
  }
}
