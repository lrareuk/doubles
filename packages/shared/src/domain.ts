import { z } from 'zod';
import * as E from './enums.js';

/**
 * Domain entities. These are the canonical shapes the API returns and the
 * engine operates on. The Swift client mirrors these as Codable structs; the
 * future RN client imports these zod schemas directly.
 *
 * Field names use camelCase here (the API contract). The Postgres tables use
 * snake_case; the db package maps between them.
 */

const uuid = z.string().uuid();
const ts = z.string(); // ISO-8601 timestamptz, serialized as string over the wire

export const Double = z.object({
  id: uuid,
  ownerUserId: uuid,
  displayName: z.string().min(1).max(40),
  handle: z
    .string()
    .min(2)
    .max(20)
    .regex(/^[a-z0-9_]+$/, 'handle must be lowercase letters, numbers or underscores'),
  personaPrompt: z.string().min(1).max(2000),
  traits: z.record(z.string(), z.unknown()).default({}),
  avatarSeed: z.string(),
  moderationStatus: E.ModerationStatus,
  createdAt: ts,
  updatedAt: ts,
});
export type Double = z.infer<typeof Double>;

export const World = z.object({
  id: uuid,
  name: z.string().min(1).max(60),
  vibe: E.WorldVibe,
  createdBy: uuid,
  seasonNumber: z.number().int().positive(),
  seasonStatus: E.SeasonStatus,
  currentEpisode: z.number().int().nonnegative(),
  seasonEndsAt: ts.nullable(),
  createdAt: ts,
});
export type World = z.infer<typeof World>;

export const WorldMember = z.object({
  id: uuid,
  worldId: uuid,
  doubleId: uuid,
  role: E.MemberRole,
  status: E.MemberStatus,
  joinedAt: ts,
});
export type WorldMember = z.infer<typeof WorldMember>;

export const Relationship = z.object({
  id: uuid,
  worldId: uuid,
  fromDoubleId: uuid,
  toDoubleId: uuid,
  affinity: z.number().int().min(-100).max(100),
  type: E.RelationshipType,
  updatedAt: ts,
});
export type Relationship = z.infer<typeof Relationship>;

export const Agenda = z.object({
  id: uuid,
  worldId: uuid,
  doubleId: uuid,
  targetEpisode: z.number().int().nonnegative(),
  intentText: z.string().min(1).max(500),
  status: E.AgendaStatus,
  createdAt: ts,
});
export type Agenda = z.infer<typeof Agenda>;

export const Episode = z.object({
  id: uuid,
  worldId: uuid,
  number: z.number().int().nonnegative(),
  status: E.EpisodeStatus,
  headline: z.string().nullable(),
  tokenUsage: z.record(z.string(), z.number()).nullable(),
  generatedAt: ts.nullable(),
  publishedAt: ts.nullable(),
});
export type Episode = z.infer<typeof Episode>;

export const Beat = z.object({
  id: uuid,
  episodeId: uuid,
  worldId: uuid,
  kind: E.BeatKind,
  participantDoubleIds: z.array(uuid),
  content: z.string(),
  visibility: E.BeatVisibility,
  moderationStatus: E.ModerationVerdict,
  createdAt: ts,
});
export type Beat = z.infer<typeof Beat>;

/** A beat as returned to a client: content is null when locked behind a reveal gate. */
export const BeatView = Beat.extend({
  content: z.string().nullable(),
  locked: z.boolean(),
});
export type BeatView = z.infer<typeof BeatView>;

export const Recap = z.object({
  id: uuid,
  episodeId: uuid,
  userId: uuid,
  narrative: z.string(),
  highlights: z.array(z.string()),
  gatedBeatIds: z.array(uuid),
  createdAt: ts,
});
export type Recap = z.infer<typeof Recap>;

export const Market = z.object({
  id: uuid,
  worldId: uuid,
  episodeOpened: z.number().int().nonnegative(),
  question: z.string(),
  options: z.array(z.object({ key: z.string(), label: z.string() })),
  resolvesOnEpisode: z.number().int().nonnegative(),
  status: E.MarketStatus,
  winningOption: z.string().nullable(),
  multiplier: z.number().positive().default(2),
  createdAt: ts,
});
export type Market = z.infer<typeof Market>;

export const Bet = z.object({
  id: uuid,
  worldId: uuid,
  userId: uuid,
  marketId: uuid,
  optionKey: z.string(),
  stakeClout: z.number().int().positive(),
  status: E.BetStatus,
  resolvedEpisode: z.number().int().nullable(),
  createdAt: ts,
});
export type Bet = z.infer<typeof Bet>;

export const PowerMove = z.object({
  id: uuid,
  worldId: uuid,
  userId: uuid,
  type: E.PowerMoveType,
  targetDoubleId: uuid.nullable(),
  payload: z.record(z.string(), z.unknown()).default({}),
  status: E.PowerMoveStatus,
  applyOnEpisode: z.number().int().nonnegative(),
  createdAt: ts,
  appliedAt: ts.nullable(),
});
export type PowerMove = z.infer<typeof PowerMove>;

export const CloutBalance = z.object({
  userId: uuid,
  worldId: uuid,
  balance: z.number().int(),
});
export type CloutBalance = z.infer<typeof CloutBalance>;

export const SeasonScore = z.object({
  id: uuid,
  worldId: uuid,
  doubleId: uuid,
  drama: z.number().int(),
  ships: z.number().int(),
  glowup: z.number().int(),
  villain: z.number().int(),
  updatedAt: ts,
});
export type SeasonScore = z.infer<typeof SeasonScore>;

export const Entitlement = z.object({
  id: uuid,
  userId: uuid,
  sku: E.EntitlementSku,
  status: E.EntitlementStatus,
  source: E.EntitlementSource,
  expiresAt: ts.nullable(),
  createdAt: ts,
});
export type Entitlement = z.infer<typeof Entitlement>;
