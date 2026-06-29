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
} from '@doubles/shared';

/** Raw snake_case rows as returned by Postgres, mapped to the camelCase contract. */

export function mapDouble(r: Record<string, unknown>): Double {
  return {
    id: r.id as string,
    ownerUserId: r.owner_user_id as string,
    displayName: r.display_name as string,
    handle: r.handle as string,
    personaPrompt: r.persona_prompt as string,
    traits: (r.traits as Record<string, unknown>) ?? {},
    avatarSeed: (r.avatar_seed as string) ?? '',
    moderationStatus: r.moderation_status as Double['moderationStatus'],
    createdAt: r.created_at as string,
    updatedAt: r.updated_at as string,
  };
}

export function mapWorld(r: Record<string, unknown>): World {
  return {
    id: r.id as string,
    name: r.name as string,
    vibe: r.vibe as World['vibe'],
    createdBy: r.created_by as string,
    seasonNumber: r.season_number as number,
    seasonStatus: r.season_status as World['seasonStatus'],
    currentEpisode: r.current_episode as number,
    seasonEndsAt: (r.season_ends_at as string) ?? null,
    createdAt: r.created_at as string,
  };
}

export function mapRelationship(r: Record<string, unknown>): Relationship {
  return {
    id: r.id as string,
    worldId: r.world_id as string,
    fromDoubleId: r.from_double_id as string,
    toDoubleId: r.to_double_id as string,
    affinity: r.affinity as number,
    type: r.type as Relationship['type'],
    updatedAt: r.updated_at as string,
  };
}

export function mapAgenda(r: Record<string, unknown>): Agenda {
  return {
    id: r.id as string,
    worldId: r.world_id as string,
    doubleId: r.double_id as string,
    targetEpisode: r.target_episode as number,
    intentText: r.intent_text as string,
    status: r.status as Agenda['status'],
    createdAt: r.created_at as string,
  };
}

export function mapEpisode(r: Record<string, unknown>): Episode {
  return {
    id: r.id as string,
    worldId: r.world_id as string,
    number: r.number as number,
    status: r.status as Episode['status'],
    headline: (r.headline as string) ?? null,
    tokenUsage: (r.token_usage as Record<string, number>) ?? null,
    generatedAt: (r.generated_at as string) ?? null,
    publishedAt: (r.published_at as string) ?? null,
  };
}

export function mapBeat(r: Record<string, unknown>): Beat {
  return {
    id: r.id as string,
    episodeId: r.episode_id as string,
    worldId: r.world_id as string,
    kind: r.kind as Beat['kind'],
    participantDoubleIds: (r.participant_double_ids as string[]) ?? [],
    content: r.content as string,
    visibility: r.visibility as Beat['visibility'],
    moderationStatus: r.moderation_status as Beat['moderationStatus'],
    createdAt: r.created_at as string,
  };
}

export function mapMarket(r: Record<string, unknown>): Market {
  return {
    id: r.id as string,
    worldId: r.world_id as string,
    episodeOpened: r.episode_opened as number,
    question: r.question as string,
    options: (r.options as { key: string; label: string }[]) ?? [],
    resolvesOnEpisode: r.resolves_on_episode as number,
    status: r.status as Market['status'],
    winningOption: (r.winning_option as string) ?? null,
    multiplier: Number(r.multiplier ?? 2),
    createdAt: r.created_at as string,
  };
}

export function mapBet(r: Record<string, unknown>): Bet {
  return {
    id: r.id as string,
    worldId: r.world_id as string,
    userId: r.user_id as string,
    marketId: r.market_id as string,
    optionKey: r.option_key as string,
    stakeClout: r.stake_clout as number,
    status: r.status as Bet['status'],
    resolvedEpisode: (r.resolved_episode as number) ?? null,
    createdAt: r.created_at as string,
  };
}

export function mapPowerMove(r: Record<string, unknown>): PowerMove {
  return {
    id: r.id as string,
    worldId: r.world_id as string,
    userId: r.user_id as string,
    type: r.type as PowerMove['type'],
    targetDoubleId: (r.target_double_id as string) ?? null,
    payload: (r.payload as Record<string, unknown>) ?? {},
    status: r.status as PowerMove['status'],
    applyOnEpisode: r.apply_on_episode as number,
    createdAt: r.created_at as string,
    appliedAt: (r.applied_at as string) ?? null,
  };
}

export function mapSeasonScore(r: Record<string, unknown>): SeasonScore {
  return {
    id: r.id as string,
    worldId: r.world_id as string,
    doubleId: r.double_id as string,
    drama: r.drama as number,
    ships: r.ships as number,
    glowup: r.glowup as number,
    villain: r.villain as number,
    updatedAt: r.updated_at as string,
  };
}
