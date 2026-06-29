import { RepoError } from '@doubles/db';
import { ZodError } from 'zod';

export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

export function error(message: string, status = 400, code?: string): Response {
  return json({ error: message, code }, status);
}

/** Map thrown errors to a clean HTTP response. */
export function handleError(err: unknown): Response {
  if (err instanceof RepoError) return error(err.message, err.status, err.code);
  if (err instanceof ZodError) {
    return json({ error: 'validation failed', issues: err.issues }, 422);
  }
  if (err instanceof HttpError) return error(err.message, err.status, err.code);
  console.error('unhandled error', err);
  return error('internal error', 500);
}

export class HttpError extends Error {
  constructor(
    message: string,
    public readonly status = 400,
    public readonly code?: string,
  ) {
    super(message);
  }
}
