import type {
  Db,
  NewBeat,
  NewMarket,
  NewRecap,
  ModerationEventWrite,
  RelationshipDeltaWrite,
  ScoreDeltaWrite,
  WorldUserDouble,
} from '@doubles/engine';
import { clampAffinity } from '@doubles/engine';
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
import type { Client } from './client.js';
import {
  mapDouble,
  mapWorld,
  mapRelationship,
  mapAgenda,
  mapEpisode,
  mapBeat,
  mapMarket,
  mapBet,
  mapPowerMove,
  mapSeasonScore,
} from './mappers.js';

function must<T>(res: { data: T; error: { message: string } | null }): T {
  if (res.error) throw new Error(`db error: ${res.error.message}`);
  return res.data;
}

/**
 * Supabase-backed implementation of the engine's Db port (brief §6/§13). Uses
 * the service-role client. Mirrors the in-memory reference adapter in
 * @doubles/engine/testing so the same engine code runs against Postgres.
 */
export class SupabaseDb implements Db {
  constructor(private readonly sb: Client) {}

  async getWorld(worldId: string): Promise<World | null> {
    const { data, error } = await this.sb.from('worlds').select('*').eq('id', worldId).maybeSingle();
    if (error) throw new Error(error.message);
    return data ? mapWorld(data) : null;
  }

  async getActiveDoubles(worldId: string): Promise<Double[]> {
    const members = must(
      await this.sb.from('world_members').select('double_id').eq('world_id', worldId).eq('status', 'active'),
    ) as { double_id: string }[];
    if (members.length === 0) return [];
    const ids = members.map((m) => m.double_id);
    const rows = must(
      await this.sb.from('doubles').select('*').in('id', ids).neq('moderation_status', 'blocked'),
    ) as Record<string, unknown>[];
    return rows.map(mapDouble);
  }

  async getWorldUsers(worldId: string): Promise<WorldUserDouble[]> {
    const doubles = await this.getActiveDoubles(worldId);
    return doubles.map((d) => ({ userId: d.ownerUserId, double: d }));
  }

  async getRelationships(worldId: string): Promise<Relationship[]> {
    const rows = must(await this.sb.from('relationships').select('*').eq('world_id', worldId)) as Record<
      string,
      unknown
    >[];
    return rows.map(mapRelationship);
  }

  async getPendingAgendas(worldId: string, targetEpisode: number): Promise<Agenda[]> {
    const rows = must(
      await this.sb
        .from('agendas')
        .select('*')
        .eq('world_id', worldId)
        .eq('target_episode', targetEpisode)
        .eq('status', 'pending'),
    ) as Record<string, unknown>[];
    return rows.map(mapAgenda);
  }

  async getRecentEpisodes(worldId: string, limit: number): Promise<Episode[]> {
    const rows = must(
      await this.sb
        .from('episodes')
        .select('*')
        .eq('world_id', worldId)
        .order('number', { ascending: false })
        .limit(limit),
    ) as Record<string, unknown>[];
    return rows.map(mapEpisode);
  }

  async getQueuedPowerMoves(worldId: string, applyOnEpisode: number): Promise<PowerMove[]> {
    const rows = must(
      await this.sb
        .from('power_moves')
        .select('*')
        .eq('world_id', worldId)
        .eq('apply_on_episode', applyOnEpisode)
        .eq('status', 'queued'),
    ) as Record<string, unknown>[];
    return rows.map(mapPowerMove);
  }

  async getEpisodeByNumber(worldId: string, number: number): Promise<Episode | null> {
    const { data, error } = await this.sb
      .from('episodes')
      .select('*')
      .eq('world_id', worldId)
      .eq('number', number)
      .maybeSingle();
    if (error) throw new Error(error.message);
    return data ? mapEpisode(data) : null;
  }

  async createEpisode(worldId: string, number: number): Promise<Episode> {
    const row = must(
      await this.sb
        .from('episodes')
        .insert({ world_id: worldId, number, status: 'planning' })
        .select('*')
        .single(),
    ) as Record<string, unknown>;
    return mapEpisode(row);
  }

  async setEpisodeStatus(episodeId: string, status: Episode['status']): Promise<void> {
    must(await this.sb.from('episodes').update({ status }).eq('id', episodeId).select('id'));
  }

  async setEpisodeHeadline(episodeId: string, headline: string): Promise<void> {
    must(await this.sb.from('episodes').update({ headline }).eq('id', episodeId).select('id'));
  }

  async publishEpisode(
    episodeId: string,
    worldId: string,
    number: number,
    tokenUsage: Record<string, number>,
  ): Promise<void> {
    const now = new Date().toISOString();
    must(
      await this.sb
        .from('episodes')
        .update({ status: 'published', token_usage: tokenUsage, generated_at: now, published_at: now })
        .eq('id', episodeId)
        .select('id'),
    );
    must(await this.sb.from('worlds').update({ current_episode: number }).eq('id', worldId).select('id'));
  }

  async insertBeats(episodeId: string, worldId: string, beats: NewBeat[]): Promise<Beat[]> {
    if (beats.length === 0) return [];
    const rows = must(
      await this.sb
        .from('beats')
        .insert(
          beats.map((b) => ({
            episode_id: episodeId,
            world_id: worldId,
            kind: b.kind,
            participant_double_ids: b.participantDoubleIds,
            content: b.content,
            visibility: b.visibility,
            moderation_status: b.moderationStatus,
          })),
        )
        .select('*'),
    ) as Record<string, unknown>[];
    return rows.map(mapBeat);
  }

  async applyRelationshipDeltas(worldId: string, deltas: RelationshipDeltaWrite[]): Promise<void> {
    for (const d of deltas) {
      const { data } = await this.sb
        .from('relationships')
        .select('*')
        .eq('world_id', worldId)
        .eq('from_double_id', d.fromDoubleId)
        .eq('to_double_id', d.toDoubleId)
        .maybeSingle();
      const current = data ? mapRelationship(data) : null;
      const affinity = clampAffinity((current?.affinity ?? 0) + d.delta);
      must(
        await this.sb
          .from('relationships')
          .upsert(
            {
              world_id: worldId,
              from_double_id: d.fromDoubleId,
              to_double_id: d.toDoubleId,
              affinity,
              type: d.type ?? current?.type ?? 'neutral',
              updated_at: new Date().toISOString(),
            },
            { onConflict: 'world_id,from_double_id,to_double_id' },
          )
          .select('id'),
      );
    }
  }

  async markAgendaOutcomes(outcomes: { agendaId: string; status: Agenda['status'] }[]): Promise<void> {
    for (const o of outcomes) {
      must(await this.sb.from('agendas').update({ status: o.status }).eq('id', o.agendaId).select('id'));
    }
  }

  async insertMarkets(worldId: string, episodeOpened: number, markets: NewMarket[]): Promise<Market[]> {
    if (markets.length === 0) return [];
    const rows = must(
      await this.sb
        .from('markets')
        .insert(
          markets.map((m) => ({
            world_id: worldId,
            episode_opened: episodeOpened,
            question: m.question,
            options: m.options,
            resolves_on_episode: m.resolvesOnEpisode,
            multiplier: m.multiplier,
            status: 'open',
          })),
        )
        .select('*'),
    ) as Record<string, unknown>[];
    return rows.map(mapMarket);
  }

  async markPowerMovesApplied(ids: string[]): Promise<void> {
    if (ids.length === 0) return;
    must(
      await this.sb
        .from('power_moves')
        .update({ status: 'applied', applied_at: new Date().toISOString() })
        .in('id', ids)
        .select('id'),
    );
  }

  async getMarketsResolvingOn(worldId: string, episode: number): Promise<Market[]> {
    const rows = must(
      await this.sb
        .from('markets')
        .select('*')
        .eq('world_id', worldId)
        .eq('resolves_on_episode', episode)
        .eq('status', 'open'),
    ) as Record<string, unknown>[];
    return rows.map(mapMarket);
  }

  async resolveMarket(marketId: string, winningOption: string | null, void_?: boolean): Promise<void> {
    must(
      await this.sb
        .from('markets')
        .update({ status: void_ ? 'void' : 'resolved', winning_option: winningOption })
        .eq('id', marketId)
        .select('id'),
    );
  }

  async getOpenBetsForMarket(marketId: string): Promise<Bet[]> {
    const rows = must(
      await this.sb.from('bets').select('*').eq('market_id', marketId).eq('status', 'open'),
    ) as Record<string, unknown>[];
    return rows.map(mapBet);
  }

  async settleBet(betId: string, status: Bet['status'], resolvedEpisode: number): Promise<void> {
    must(
      await this.sb
        .from('bets')
        .update({ status, resolved_episode: resolvedEpisode })
        .eq('id', betId)
        .select('id'),
    );
  }

  async adjustClout(userId: string, worldId: string, delta: number): Promise<void> {
    const { data } = await this.sb
      .from('clout_balances')
      .select('balance')
      .eq('user_id', userId)
      .eq('world_id', worldId)
      .maybeSingle();
    const balance = ((data?.balance as number) ?? 0) + delta;
    must(
      await this.sb
        .from('clout_balances')
        .upsert({ user_id: userId, world_id: worldId, balance }, { onConflict: 'user_id,world_id' })
        .select('user_id'),
    );
  }

  async applyScoreDeltas(worldId: string, deltas: ScoreDeltaWrite[]): Promise<void> {
    for (const d of deltas) {
      const { data } = await this.sb
        .from('season_scores')
        .select('*')
        .eq('world_id', worldId)
        .eq('double_id', d.doubleId)
        .maybeSingle();
      const cur = data ? mapSeasonScore(data) : null;
      must(
        await this.sb
          .from('season_scores')
          .upsert(
            {
              world_id: worldId,
              double_id: d.doubleId,
              drama: (cur?.drama ?? 0) + d.drama,
              ships: (cur?.ships ?? 0) + d.ships,
              glowup: (cur?.glowup ?? 0) + d.glowup,
              villain: (cur?.villain ?? 0) + d.villain,
              updated_at: new Date().toISOString(),
            },
            { onConflict: 'world_id,double_id' },
          )
          .select('id'),
      );
    }
  }

  async getSeasonScores(worldId: string): Promise<SeasonScore[]> {
    const rows = must(await this.sb.from('season_scores').select('*').eq('world_id', worldId)) as Record<
      string,
      unknown
    >[];
    return rows.map(mapSeasonScore);
  }

  async setSeasonStatus(worldId: string, status: World['seasonStatus']): Promise<void> {
    must(await this.sb.from('worlds').update({ season_status: status }).eq('id', worldId).select('id'));
  }

  async upsertRecap(episodeId: string, recap: NewRecap): Promise<void> {
    must(
      await this.sb
        .from('recaps')
        .upsert(
          {
            episode_id: episodeId,
            user_id: recap.userId,
            narrative: recap.narrative,
            highlights: recap.highlights,
            gated_beat_ids: recap.gatedBeatIds,
          },
          { onConflict: 'episode_id,user_id' },
        )
        .select('id'),
    );
  }

  async recordModerationEvents(events: ModerationEventWrite[]): Promise<void> {
    if (events.length === 0) return;
    must(
      await this.sb.from('moderation_events').insert(
        events.map((e) => ({
          subject_type: e.subjectType,
          subject_id: e.subjectId,
          verdict: e.verdict,
          reason: e.reason ?? null,
        })),
      ).select('id'),
    );
  }
}
