/**
 * Seed one demo world with five doubles, neutral relationships and starting
 * clout (brief §12/§14). Safe to run repeatedly: users are looked up by email,
 * memberships/relationships/clout upsert, and the world is reused if present.
 *
 *   pnpm seed   (from repo root)
 *
 * Drives the same @doubles/db code paths the API uses, so the seed exercises the
 * real flow rather than raw SQL.
 */
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createServiceClient, Repo, type Client } from '@doubles/db';
import type { WorldVibe } from '@doubles/shared';

function loadEnv(): void {
  const here = dirname(fileURLToPath(import.meta.url));
  const envPath = resolve(here, '../../.env');
  try {
    for (const line of readFileSync(envPath, 'utf8').split('\n')) {
      const t = line.trim();
      if (!t || t.startsWith('#')) continue;
      const eq = t.indexOf('=');
      if (eq === -1) continue;
      const key = t.slice(0, eq).trim();
      let v = t.slice(eq + 1).trim();
      if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
      if (!(key in process.env)) process.env[key] = v;
    }
  } catch {
    /* rely on ambient env */
  }
}

const CAST: { email: string; displayName: string; handle: string; persona: string }[] = [
  {
    email: 'aria@doubles.dev',
    displayName: 'Aria',
    handle: 'aria',
    persona: 'Aria is the chaos agent — chronically online, allergic to peace, starts the drama then films it.',
  },
  {
    email: 'bex@doubles.dev',
    displayName: 'Bex',
    handle: 'bex',
    persona: 'Bex is the soft-hearted peacemaker who somehow ends up at the center of every love triangle.',
  },
  {
    email: 'cory@doubles.dev',
    displayName: 'Cory',
    handle: 'cory',
    persona: 'Cory is the strategist — calm, calculating, always three alliances deep, never caught.',
  },
  {
    email: 'dru@doubles.dev',
    displayName: 'Dru',
    handle: 'dru',
    persona: 'Dru is the wildcard romantic, falls hard and fast, blocks and unblocks in the same hour.',
  },
  {
    email: 'eli@doubles.dev',
    displayName: 'Eli',
    handle: 'eli',
    persona: 'Eli is the deadpan observer who pretends not to care but quietly runs the group chat.',
  },
];

const SEED_PASSWORD = 'doubles-seed-password-123';
const WORLD_NAME = 'The Group Chat';
const WORLD_VIBE: WorldVibe = 'messy';

async function ensureAuthUser(admin: Client, email: string): Promise<string> {
  // Look up an existing user by email (paginate a couple of pages — seed is tiny).
  for (let page = 1; page <= 5; page++) {
    const { data } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    const found = data.users.find((u) => u.email === email);
    if (found) return found.id;
    if (data.users.length < 200) break;
  }
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password: SEED_PASSWORD,
    email_confirm: true,
  });
  if (error || !data.user) throw new Error(`failed to create ${email}: ${error?.message}`);
  return data.user.id;
}

async function main(): Promise<void> {
  loadEnv();
  const env = {
    SUPABASE_URL: process.env.SUPABASE_URL!,
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY!,
    SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY,
  };
  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env');
  }

  const sb = createServiceClient(env);
  const repo = new Repo(sb);

  // 1. Users + doubles (age-verified; self-authored).
  const userIds: string[] = [];
  for (const c of CAST) {
    const userId = await ensureAuthUser(sb, c.email);
    userIds.push(userId);
    await repo.ensureUser(userId);
    await repo.ageVerify(userId);
    await repo.upsertMyDouble(
      userId,
      { displayName: c.displayName, handle: c.handle, personaPrompt: c.persona },
      'ok',
    );
    console.log(`✓ ${c.handle} (${userId})`);
  }

  // 2. World hosted by the first cast member (reuse if it already exists).
  const { data: existingWorld } = await sb
    .from('worlds')
    .select('id')
    .eq('name', WORLD_NAME)
    .eq('created_by', userIds[0]!)
    .maybeSingle();

  let worldId: string;
  if (existingWorld) {
    worldId = existingWorld.id as string;
    console.log(`• reusing world ${worldId}`);
  } else {
    const world = await repo.createWorld(userIds[0]!, { name: WORLD_NAME, vibe: WORLD_VIBE });
    worldId = world.id;
    console.log(`✓ created world ${worldId}`);
  }

  // 3. Everyone else joins (membership/relationships/clout upsert — idempotent).
  for (let i = 1; i < userIds.length; i++) {
    const token = await repo.createInvite(worldId, userIds[0]!);
    await repo.joinWorld(userIds[i]!, token);
    console.log(`✓ ${CAST[i]!.handle} joined`);
  }

  console.log('\nSeed complete.');
  console.log(`WORLD_ID=${worldId}`);
  console.log('Run an episode:  pnpm --filter @doubles/api run-episode ' + worldId);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
