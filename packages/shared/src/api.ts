import { z } from 'zod';
import * as E from './enums.js';
import { Double, World, WorldMember, BeatView, SeasonScore } from './domain.js';

/**
 * API request/response contracts. Every route handler validates its input with
 * the matching `*Input` schema (brief §8/§13). Response shapes are exported so
 * clients can rely on them.
 */

// ---- doubles -------------------------------------------------------------
export const UpsertDoubleInput = z.object({
  displayName: z.string().min(1).max(40),
  handle: z
    .string()
    .min(2)
    .max(20)
    .regex(/^[a-z0-9_]+$/),
  personaPrompt: z.string().min(1).max(2000),
  traits: z.record(z.string(), z.unknown()).optional(),
  avatarSeed: z.string().optional(),
});
export type UpsertDoubleInput = z.infer<typeof UpsertDoubleInput>;

// ---- worlds --------------------------------------------------------------
export const CreateWorldInput = z.object({
  name: z.string().min(1).max(60),
  vibe: E.WorldVibe,
  seasonLengthDays: z.number().int().positive().max(60).optional(),
});
export type CreateWorldInput = z.infer<typeof CreateWorldInput>;

export const InviteInput = z.object({
  expiresInHours: z.number().int().positive().max(168).optional(),
});
export type InviteInput = z.infer<typeof InviteInput>;

export const JoinWorldInput = z.object({
  token: z.string().min(1),
});
export type JoinWorldInput = z.infer<typeof JoinWorldInput>;

// ---- game ----------------------------------------------------------------
export const SetAgendaInput = z.object({
  intentText: z.string().min(1).max(500),
});
export type SetAgendaInput = z.infer<typeof SetAgendaInput>;

export const PlaceBetInput = z.object({
  marketId: z.string().uuid(),
  optionKey: z.string().min(1),
  stakeClout: z.number().int().positive(),
});
export type PlaceBetInput = z.infer<typeof PlaceBetInput>;

export const PowerMoveInput = z.object({
  type: E.PowerMoveType,
  targetDoubleId: z.string().uuid().nullable().optional(),
  payload: z.record(z.string(), z.unknown()).optional(),
});
export type PowerMoveInput = z.infer<typeof PowerMoveInput>;

// ---- monetization --------------------------------------------------------
export const IapValidateInput = z.object({
  sku: E.EntitlementSku,
  /** Opaque receipt blob from the store; validated by the IapValidator stub. */
  receipt: z.string().min(1),
  platform: z.enum(['apple', 'google']).default('apple'),
});
export type IapValidateInput = z.infer<typeof IapValidateInput>;

// ---- responses -----------------------------------------------------------
export const Standing = z.object({
  double: Double,
  score: SeasonScore.nullable(),
});
export type Standing = z.infer<typeof Standing>;

export const WorldStateResponse = z.object({
  world: World,
  myDouble: Double.nullable(),
  members: z.array(WorldMember),
  standings: z.array(Standing),
  cloutBalance: z.number().int(),
  powerMovesRemaining: z.number().int(),
});
export type WorldStateResponse = z.infer<typeof WorldStateResponse>;

export const EpisodeViewResponse = z.object({
  number: z.number().int(),
  status: E.EpisodeStatus,
  headline: z.string().nullable(),
  beats: z.array(BeatView),
});
export type EpisodeViewResponse = z.infer<typeof EpisodeViewResponse>;

export const ApiError = z.object({
  error: z.string(),
  code: z.string().optional(),
});
export type ApiError = z.infer<typeof ApiError>;
