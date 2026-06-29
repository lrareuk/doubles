import type {
  Double,
  World,
  Relationship,
  Agenda,
  Episode,
  Beat,
  Market,
  Bet,
  PowerMove,
  SeasonScore,
  RelationshipType,
  BeatKind,
  BeatVisibility,
} from '@doubles/shared';

/**
 * Injected dependencies that keep the engine pure and unit-testable (brief §6,
 * §13). The engine NEVER imports Next.js or Supabase — it talks to these ports.
 * The db package supplies a Supabase-backed Db; tests supply an in-memory one.
 */

/** Deterministic clock so episodes are reproducible in tests. */
export interface Clock {
  now(): Date;
}

export interface Logger {
  info(msg: string, meta?: Record<string, unknown>): void;
  warn(msg: string, meta?: Record<string, unknown>): void;
  error(msg: string, meta?: Record<string, unknown>): void;
}

// ---- write payloads ------------------------------------------------------
export interface NewBeat {
  kind: BeatKind;
  participantDoubleIds: string[];
  content: string;
  visibility: BeatVisibility;
  moderationStatus: 'ok' | 'blocked';
}

export interface NewMarket {
  question: string;
  options: { key: string; label: string }[];
  resolvesOnEpisode: number;
  multiplier: number;
}

export interface RelationshipDeltaWrite {
  fromDoubleId: string;
  toDoubleId: string;
  delta: number;
  type?: RelationshipType;
}

export interface ScoreDeltaWrite {
  doubleId: string;
  drama: number;
  ships: number;
  glowup: number;
  villain: number;
}

export interface NewRecap {
  userId: string;
  narrative: string;
  highlights: string[];
  gatedBeatIds: string[];
}

export interface ModerationEventWrite {
  subjectType: 'persona' | 'beat';
  subjectId: string;
  verdict: 'ok' | 'blocked';
  reason?: string;
}

/** A user participating in a world, with the double they authored. */
export interface WorldUserDouble {
  userId: string;
  double: Double;
}

/**
 * The data port the engine depends on. Every method is storage-agnostic.
 * Implementations: SupabaseDb (db package) and InMemoryDb (engine/testing).
 */
export interface Db {
  // --- reads for gather() ---
  getWorld(worldId: string): Promise<World | null>;
  getActiveDoubles(worldId: string): Promise<Double[]>;
  getWorldUsers(worldId: string): Promise<WorldUserDouble[]>;
  getRelationships(worldId: string): Promise<Relationship[]>;
  getPendingAgendas(worldId: string, targetEpisode: number): Promise<Agenda[]>;
  getRecentEpisodes(worldId: string, limit: number): Promise<Episode[]>;
  getQueuedPowerMoves(worldId: string, applyOnEpisode: number): Promise<PowerMove[]>;

  // --- idempotency ---
  getEpisodeByNumber(worldId: string, number: number): Promise<Episode | null>;

  // --- episode lifecycle ---
  createEpisode(worldId: string, number: number): Promise<Episode>;
  setEpisodeStatus(episodeId: string, status: Episode['status']): Promise<void>;
  setEpisodeHeadline(episodeId: string, headline: string): Promise<void>;
  publishEpisode(
    episodeId: string,
    worldId: string,
    number: number,
    tokenUsage: Record<string, number>,
  ): Promise<void>;

  // --- applyState ---
  insertBeats(episodeId: string, worldId: string, beats: NewBeat[]): Promise<Beat[]>;
  applyRelationshipDeltas(worldId: string, deltas: RelationshipDeltaWrite[]): Promise<void>;
  markAgendaOutcomes(
    outcomes: { agendaId: string; status: Agenda['status'] }[],
  ): Promise<void>;
  insertMarkets(worldId: string, episodeOpened: number, markets: NewMarket[]): Promise<Market[]>;
  markPowerMovesApplied(ids: string[]): Promise<void>;

  // --- resolveBets ---
  getMarketsResolvingOn(worldId: string, episode: number): Promise<Market[]>;
  resolveMarket(marketId: string, winningOption: string | null, void_?: boolean): Promise<void>;
  getOpenBetsForMarket(marketId: string): Promise<Bet[]>;
  settleBet(betId: string, status: Bet['status'], resolvedEpisode: number): Promise<void>;
  adjustClout(userId: string, worldId: string, delta: number): Promise<void>;

  // --- score ---
  applyScoreDeltas(worldId: string, deltas: ScoreDeltaWrite[]): Promise<void>;
  getSeasonScores(worldId: string): Promise<SeasonScore[]>;
  setSeasonStatus(worldId: string, status: World['seasonStatus']): Promise<void>;

  // --- recaps ---
  upsertRecap(episodeId: string, recap: NewRecap): Promise<void>;

  // --- moderation ---
  recordModerationEvents(events: ModerationEventWrite[]): Promise<void>;
}
