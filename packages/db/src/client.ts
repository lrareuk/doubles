import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Supabase client factories. The server uses the SERVICE-ROLE key (bypasses RLS)
 * and is the single access path for the engine and most API routes. The anon
 * client is used only to verify a caller's JWT.
 *
 * Never expose the service-role key to a client (brief §9).
 */
export interface DbEnv {
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  SUPABASE_ANON_KEY?: string;
}

export type Client = SupabaseClient;

export function createServiceClient(env: DbEnv): Client {
  return createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** Resolve a Supabase auth user id from a Bearer access token. */
export async function getUserIdFromToken(env: DbEnv, accessToken: string): Promise<string | null> {
  const client = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY ?? env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser(accessToken);
  if (error || !data.user) return null;
  return data.user.id;
}
