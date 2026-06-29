import { z } from 'zod';

/**
 * Canonical enums for Doubles. These mirror the Postgres enum/check constraints
 * in supabase/migrations and the Swift `Enums.swift` mirror. Keep all three in sync.
 */

export const UserStatus = z.enum(['active', 'removed']);
export type UserStatus = z.infer<typeof UserStatus>;

export const ModerationStatus = z.enum(['pending', 'ok', 'blocked']);
export type ModerationStatus = z.infer<typeof ModerationStatus>;

export const WorldVibe = z.enum(['messy', 'wholesome_chaos', 'villain_arc', 'nobodys_safe']);
export type WorldVibe = z.infer<typeof WorldVibe>;

export const SeasonStatus = z.enum(['active', 'finale', 'ended']);
export type SeasonStatus = z.infer<typeof SeasonStatus>;

export const MemberRole = z.enum(['host', 'member']);
export type MemberRole = z.infer<typeof MemberRole>;

export const MemberStatus = z.enum(['active', 'left', 'removed']);
export type MemberStatus = z.infer<typeof MemberStatus>;

export const RelationshipType = z.enum(['neutral', 'friend', 'ally', 'crush', 'rival', 'ex']);
export type RelationshipType = z.infer<typeof RelationshipType>;

export const AgendaStatus = z.enum(['pending', 'in_progress', 'succeeded', 'failed']);
export type AgendaStatus = z.infer<typeof AgendaStatus>;

export const EpisodeStatus = z.enum([
  'planning',
  'generating',
  'moderating',
  'published',
  'failed',
]);
export type EpisodeStatus = z.infer<typeof EpisodeStatus>;

export const BeatKind = z.enum(['post', 'dm', 'scene', 'twist', 'ship']);
export type BeatKind = z.infer<typeof BeatKind>;

export const BeatVisibility = z.enum(['public', 'reveal_gated']);
export type BeatVisibility = z.infer<typeof BeatVisibility>;

export const MarketStatus = z.enum(['open', 'resolved', 'void']);
export type MarketStatus = z.infer<typeof MarketStatus>;

export const BetStatus = z.enum(['open', 'won', 'lost', 'void']);
export type BetStatus = z.infer<typeof BetStatus>;

export const PowerMoveType = z.enum([
  'whisper',
  'rumour',
  'sabotage',
  'force_encounter',
  'spotlight',
]);
export type PowerMoveType = z.infer<typeof PowerMoveType>;

export const PowerMoveStatus = z.enum(['queued', 'applied', 'expired']);
export type PowerMoveStatus = z.infer<typeof PowerMoveStatus>;

export const EntitlementSku = z.enum([
  'sub_monthly',
  'season_pass',
  'consumable_powerpack',
  'consumable_cloutpack',
  'consumable_chaositem',
  'cosmetic_avatar',
  'cosmetic_season_theme',
  'cosmetic_recap_card',
]);
export type EntitlementSku = z.infer<typeof EntitlementSku>;

export const EntitlementStatus = z.enum(['active', 'expired']);
export type EntitlementStatus = z.infer<typeof EntitlementStatus>;

export const EntitlementSource = z.enum(['subscription', 'season_pass', 'consumable', 'grant']);
export type EntitlementSource = z.infer<typeof EntitlementSource>;

export const RevealSource = z.enum(['subscription', 'consumable']);
export type RevealSource = z.infer<typeof RevealSource>;

export const ModerationSubject = z.enum(['persona', 'beat']);
export type ModerationSubject = z.infer<typeof ModerationSubject>;

export const ModerationVerdict = z.enum(['ok', 'blocked']);
export type ModerationVerdict = z.infer<typeof ModerationVerdict>;
