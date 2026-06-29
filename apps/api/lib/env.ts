import { HttpError } from './responses';

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

/** Veriff age-assurance config (server-only). Keys never reach the client. */
export interface VeriffEnv {
  apiKey: string;
  hmacSecret: string;
  baseUrl: string;
  callbackUrl?: string;
}

/**
 * Resolve Veriff config, or throw a clean 503 if age assurance isn't configured
 * yet (so the rest of the API keeps working before the vendor is wired up).
 */
export function getVeriff(): VeriffEnv {
  const e = process.env;
  const apiKey = e.VERIFF_API_KEY;
  const hmacSecret = e.VERIFF_HMAC_SECRET;
  if (!apiKey || !hmacSecret) {
    throw new HttpError('age assurance is not configured', 503, 'age_assurance_unconfigured');
  }
  return {
    apiKey,
    hmacSecret,
    // The Age-Estimation integration has its own base URL; falls back to the
    // generic Veriff host if a dedicated one isn't provided.
    baseUrl: e.VERIFF_BASE_URL ?? 'https://stationapi.veriff.com',
    callbackUrl: e.VERIFF_CALLBACK_URL,
  };
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
