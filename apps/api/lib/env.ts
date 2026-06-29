/**
 * Server-only environment access. Never import this from client components.
 * All secrets stay server-side (brief §9).
 */
export interface ApiEnv {
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  JOB_SECRET: string;
  AI_PROVIDER: string;
  ANTHROPIC_API_KEY?: string;
  DOUBLES_MODEL_PLAN?: string;
  DOUBLES_MODEL_BEAT?: string;
  DOUBLES_MODEL_RECAP?: string;
  DOUBLES_USE_BATCH?: string;
  DOUBLES_BEAT_CAP?: string;
  DOUBLES_TOKEN_BUDGET?: string;
}

export function getEnv(): ApiEnv {
  const e = process.env;
  const required = (key: string): string => {
    const v = e[key];
    if (!v) throw new Error(`Missing required env var: ${key}`);
    return v;
  };
  return {
    SUPABASE_URL: required('SUPABASE_URL'),
    SUPABASE_ANON_KEY: required('SUPABASE_ANON_KEY'),
    SUPABASE_SERVICE_ROLE_KEY: required('SUPABASE_SERVICE_ROLE_KEY'),
    JOB_SECRET: required('JOB_SECRET'),
    AI_PROVIDER: e.AI_PROVIDER ?? 'mock',
    ANTHROPIC_API_KEY: e.ANTHROPIC_API_KEY,
    DOUBLES_MODEL_PLAN: e.DOUBLES_MODEL_PLAN,
    DOUBLES_MODEL_BEAT: e.DOUBLES_MODEL_BEAT,
    DOUBLES_MODEL_RECAP: e.DOUBLES_MODEL_RECAP,
    DOUBLES_USE_BATCH: e.DOUBLES_USE_BATCH,
    DOUBLES_BEAT_CAP: e.DOUBLES_BEAT_CAP,
    DOUBLES_TOKEN_BUDGET: e.DOUBLES_TOKEN_BUDGET,
  };
}
