import type { Double, Relationship, Agenda, PowerMove } from '@doubles/shared';

/**
 * The compact, token-bounded world snapshot that gather() builds and
 * planEpisode() consumes. The stable parts (cast block) are what the real
 * Claude client marks for prompt caching.
 */
export interface CastMember {
  doubleId: string;
  displayName: string;
  handle: string;
  persona: string;
  traits: Record<string, unknown>;
}

export interface RelationshipEdge {
  fromDoubleId: string;
  toDoubleId: string;
  fromHandle: string;
  toHandle: string;
  affinity: number;
  type: Relationship['type'];
}

export interface WorldContext {
  worldId: string;
  worldName: string;
  vibe: string;
  seasonNumber: number;
  /** The episode number we are about to generate. */
  episodeNumber: number;
  /** Stable cast block — cached across all generation calls. */
  cast: CastMember[];
  relationships: RelationshipEdge[];
  agendas: { agendaId: string; doubleId: string; handle: string; intent: string }[];
  recentEpisodeSummaries: { number: number; headline: string }[];
  /** Open markets that resolve on THIS episode — the planner picks winners. */
  marketsResolvingNow: {
    id: string;
    question: string;
    options: { key: string; label: string }[];
  }[];
  queuedPowerMoves: {
    id: string;
    type: PowerMove['type'];
    ownerDoubleId: string | null;
    ownerHandle: string | null;
    targetDoubleId: string | null;
    targetHandle: string | null;
    payload: Record<string, unknown>;
  }[];
  /** Caps the planner must respect. */
  beatCap: number;
}

/** Inputs for writing a per-user recap. */
export interface RecapInput {
  userHandle: string;
  episodeNumber: number;
  worldName: string;
  headline: string;
  relevantBeats: { kind: string; content: string }[];
  worldHeadlines: string[];
}

export { type Double, type Agenda };
