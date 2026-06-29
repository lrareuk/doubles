import {
  GAME,
  type Double,
  type World,
  type WorldMember,
  type Market,
  type Bet,
  type Beat,
  type BeatView,
  type Entitlement,
  type SeasonScore,
  type UpsertDoubleInput,
  type CreateWorldInput,
  type EntitlementSku,
} from '@doubles/shared';
import {
  dailyPowerMoveAllowance,
  canSpendPowerMove,
  canAffordBet,
  concurrentWorldLimit,
} from '@doubles/engine';
import type { Client } from './client.js';
import type { Relationship } from '@doubles/shared';
import {
  mapDouble,
  mapWorld,
  mapMarket,
  mapBet,
  mapBeat,
  mapSeasonScore,
  mapRelationship,
} from './mappers.js';

function must<T>(res: { data: T; error: { message: string } | null }): T {
  if (res.error) throw new Error(`db error: ${res.error.message}`);
  return res.data;
}

/** A bet enriched with display fields the client needs (market question, payout). */
export interface EnrichedBet {
  id: string;
  marketId: string;
  marketQuestion: string;
  optionLabel: string;
  stake: number;
  status: Bet['status'];
  potentialPayout: number;
}

/** Thrown for caller-facing validation failures; routes map these to 4xx. */
export class RepoError extends Error {
  constructor(
    message: string,
    public readonly status: number = 400,
    public readonly code?: string,
  ) {
    super(message);
  }
}

/**
 * Data access for the API route handlers. Enforces the consent/ownership rules
 * (brief §9) in code: a double is only ever upserted for its own owner, and
 * deletion purges the user's content.
 */
export class Repo {
  constructor(private readonly sb: Client) {}

  // ---- identity ----
  async ensureUser(userId: string): Promise<void> {
    must(await this.sb.from('users').upsert({ id: userId }, { onConflict: 'id' }).select('id'));
  }

  async isAgeVerified(userId: string): Promise<boolean> {
    const { data } = await this.sb.from('users').select('age_verified').eq('id', userId).maybeSingle();
    return Boolean(data?.age_verified);
  }

  async ageVerify(userId: string): Promise<void> {
    await this.ensureUser(userId);
    must(
      await this.sb
        .from('users')
        .update({ age_verified: true, age_verified_at: new Date().toISOString() })
        .eq('id', userId)
        .select('id'),
    );
    await this.audit(userId, 'age_verify', null, {});
  }

  // ---- age assurance (Veriff) ----
  /** Record that an age-assurance session has been created for the user. */
  async startAgeVerification(userId: string, ref: string): Promise<void> {
    await this.ensureUser(userId);
    must(
      await this.sb
        .from('users')
        .update({ age_verification_ref: ref, age_verification_status: 'pending' })
        .eq('id', userId)
        .select('id'),
    );
    await this.audit(userId, 'age_verify_start', null, { ref });
  }

  /** Mark the user as 18+ after a HMAC-verified vendor decision. Idempotent. */
  async markAgeApproved(userId: string, ref: string): Promise<void> {
    if (await this.isAgeVerified(userId)) return; // already verified — ignore duplicate webhooks
    must(
      await this.sb
        .from('users')
        .update({
          age_verified: true,
          age_verified_at: new Date().toISOString(),
          age_verification_status: 'approved',
          age_verification_ref: ref,
        })
        .eq('id', userId)
        .select('id'),
    );
    await this.audit(userId, 'age_verify_approved', null, { ref });
  }

  /** Record a non-pass age decision (declined / under-threshold / expired). */
  async markAgeRejected(userId: string, ref: string): Promise<void> {
    must(
      await this.sb
        .from('users')
        .update({ age_verification_status: 'rejected', age_verification_ref: ref })
        .eq('id', userId)
        .select('id'),
    );
    await this.audit(userId, 'age_verify_rejected', null, { ref });
  }

  // ---- doubles (self-authored only) ----
  async getMyDouble(userId: string): Promise<Double | null> {
    const { data } = await this.sb.from('doubles').select('*').eq('owner_user_id', userId).maybeSingle();
    return data ? mapDouble(data) : null;
  }

  async upsertMyDouble(
    userId: string,
    input: UpsertDoubleInput,
    moderationStatus: 'ok' | 'blocked',
  ): Promise<Double> {
    await this.ensureUser(userId);
    const row = must(
      await this.sb
        .from('doubles')
        .upsert(
          {
            owner_user_id: userId,
            display_name: input.displayName,
            handle: input.handle,
            persona_prompt: input.personaPrompt,
            traits: input.traits ?? {},
            avatar_seed: input.avatarSeed ?? input.handle,
            moderation_status: moderationStatus,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'owner_user_id' },
        )
        .select('*')
        .single(),
    ) as Record<string, unknown>;
    await this.audit(userId, 'upsert_double', null, { handle: input.handle });
    return mapDouble(row);
  }

  /** Hard deletion: removes the user's double + all derived content (brief §9). */
  async deleteMyDoubleAndPurge(userId: string): Promise<void> {
    const dbl = await this.getMyDouble(userId);
    if (!dbl) return;
    // ON DELETE CASCADE on doubles handles memberships, relationships, agendas,
    // season_scores, queued power moves targeting it. Beats reference the double
    // only via a uuid[] column (no FK), so scrub those participant references.
    await this.sb.from('doubles').delete().eq('id', dbl.id).eq('owner_user_id', userId);
    await this.audit(userId, 'delete_double', null, { doubleId: dbl.id });
  }

  /**
   * Full account erasure (UK GDPR right to erasure, Art 17). Deleting the `users`
   * row cascades to ALL user-keyed data: the double (and its world_members,
   * relationships, agendas, season_scores), recaps, bets, power_moves,
   * clout_balances, entitlements, reveal_unlocks, device_tokens and world_invites.
   * `audit_log.user_id` is ON DELETE SET NULL, leaving an anonymised erasure trail.
   * Finally we delete the Supabase Auth identity (the sign-in email) itself.
   */
  async deleteAccount(userId: string): Promise<void> {
    // Logged while the user still exists; the cascade anonymises this row (SET NULL).
    await this.audit(userId, 'delete_account', null, {});

    const { error } = await this.sb.from('users').delete().eq('id', userId);
    if (error) throw new Error(`account purge failed: ${error.message}`);

    // Remove the authentication identity (email) for complete erasure.
    const { error: authErr } = await this.sb.auth.admin.deleteUser(userId);
    if (authErr) throw new Error(`auth identity deletion failed: ${authErr.message}`);
  }

  // ---- worlds & seasons ----
  async createWorld(userId: string, input: CreateWorldInput): Promise<World> {
    await this.ensureUser(userId);
    const myDouble = await this.getMyDouble(userId);
    if (!myDouble) throw new RepoError('create your double first', 409, 'no_double');

    await this.enforceConcurrentWorldLimit(userId);

    const lengthDays = input.seasonLengthDays ?? GAME.SEASON_LENGTH_DAYS;
    const endsAt = new Date(Date.now() + lengthDays * 86_400_000).toISOString();
    const world = mapWorld(
      must(
        await this.sb
          .from('worlds')
          .insert({ name: input.name, vibe: input.vibe, created_by: userId, season_ends_at: endsAt })
          .select('*')
          .single(),
      ) as Record<string, unknown>,
    );
    await this.joinWorldInternal(world.id, myDouble, 'host');
    await this.audit(userId, 'create_world', world.id, { name: input.name });
    return world;
  }

  async createInvite(worldId: string, userId: string, expiresInHours = 72): Promise<string> {
    const token = cryptoToken();
    must(
      await this.sb
        .from('world_invites')
        .insert({
          world_id: worldId,
          token,
          created_by: userId,
          expires_at: new Date(Date.now() + expiresInHours * 3_600_000).toISOString(),
        })
        .select('id'),
    );
    return token;
  }

  async joinWorld(userId: string, token: string): Promise<World> {
    const myDouble = await this.getMyDouble(userId);
    if (!myDouble) throw new RepoError('create your double first', 409, 'no_double');

    const { data: invite } = await this.sb
      .from('world_invites')
      .select('*')
      .eq('token', token)
      .maybeSingle();
    if (!invite) throw new RepoError('invalid invite token', 404, 'bad_token');
    if (invite.expires_at && new Date(invite.expires_at as string) < new Date()) {
      throw new RepoError('invite expired', 410, 'expired');
    }
    await this.enforceConcurrentWorldLimit(userId);

    const world = await this.getWorld(invite.world_id as string);
    if (!world) throw new RepoError('world not found', 404);
    await this.joinWorldInternal(world.id, myDouble, 'member');
    await this.sb.from('world_invites').update({ used_at: new Date().toISOString() }).eq('id', invite.id);
    await this.audit(userId, 'join_world', world.id, {});
    return world;
  }

  private async joinWorldInternal(worldId: string, myDouble: Double, role: 'host' | 'member'): Promise<void> {
    must(
      await this.sb
        .from('world_members')
        .upsert(
          { world_id: worldId, double_id: myDouble.id, role, status: 'active' },
          { onConflict: 'world_id,double_id' },
        )
        .select('id'),
    );
    // Seed neutral directed relationships with every existing active member.
    const existing = must(
      await this.sb.from('world_members').select('double_id').eq('world_id', worldId).eq('status', 'active'),
    ) as { double_id: string }[];
    const rels: Record<string, unknown>[] = [];
    for (const m of existing) {
      if (m.double_id === myDouble.id) continue;
      rels.push({ world_id: worldId, from_double_id: myDouble.id, to_double_id: m.double_id });
      rels.push({ world_id: worldId, from_double_id: m.double_id, to_double_id: myDouble.id });
    }
    if (rels.length) {
      await this.sb.from('relationships').upsert(rels, { onConflict: 'world_id,from_double_id,to_double_id' });
    }
    // Starting clout for this user in this world.
    await this.sb
      .from('clout_balances')
      .upsert(
        { user_id: myDouble.ownerUserId, world_id: worldId, balance: GAME.STARTING_CLOUT },
        { onConflict: 'user_id,world_id' },
      );
    // Initialise a season score row.
    await this.sb
      .from('season_scores')
      .upsert({ world_id: worldId, double_id: myDouble.id }, { onConflict: 'world_id,double_id' });
  }

  async getWorld(worldId: string): Promise<World | null> {
    const { data } = await this.sb.from('worlds').select('*').eq('id', worldId).maybeSingle();
    return data ? mapWorld(data) : null;
  }

  /** Worlds the caller's double is an active member of (powers the app's world list). */
  async myWorlds(userId: string): Promise<World[]> {
    const myDouble = await this.getMyDouble(userId);
    if (!myDouble) return [];
    const members = must(
      await this.sb
        .from('world_members')
        .select('world_id')
        .eq('double_id', myDouble.id)
        .eq('status', 'active'),
    ) as { world_id: string }[];
    if (members.length === 0) return [];
    const ids = members.map((m) => m.world_id);
    const rows = must(await this.sb.from('worlds').select('*').in('id', ids)) as Record<
      string,
      unknown
    >[];
    return rows.map(mapWorld);
  }

  async getRelationships(worldId: string): Promise<Relationship[]> {
    const rows = must(
      await this.sb.from('relationships').select('*').eq('world_id', worldId),
    ) as Record<string, unknown>[];
    return rows.map(mapRelationship);
  }

  async getMembers(worldId: string): Promise<WorldMember[]> {
    const rows = must(
      await this.sb.from('world_members').select('*').eq('world_id', worldId).eq('status', 'active'),
    ) as Record<string, unknown>[];
    return rows.map((r) => ({
      id: r.id as string,
      worldId: r.world_id as string,
      doubleId: r.double_id as string,
      role: r.role as WorldMember['role'],
      status: r.status as WorldMember['status'],
      joinedAt: r.joined_at as string,
    }));
  }

  async getStandings(worldId: string): Promise<{ double: Double; score: SeasonScore | null }[]> {
    const members = await this.getMembers(worldId);
    if (members.length === 0) return [];
    const ids = members.map((m) => m.doubleId);
    const doubles = (
      must(await this.sb.from('doubles').select('*').in('id', ids)) as Record<string, unknown>[]
    ).map(mapDouble);
    const scores = (
      must(await this.sb.from('season_scores').select('*').eq('world_id', worldId)) as Record<
        string,
        unknown
      >[]
    ).map(mapSeasonScore);
    return doubles.map((d) => ({
      double: d,
      score: scores.find((s) => s.doubleId === d.id) ?? null,
    }));
  }

  async getClout(worldId: string, userId: string): Promise<number> {
    const { data } = await this.sb
      .from('clout_balances')
      .select('balance')
      .eq('user_id', userId)
      .eq('world_id', worldId)
      .maybeSingle();
    return (data?.balance as number) ?? 0;
  }

  async powerMovesRemaining(worldId: string, userId: string): Promise<number> {
    const used = await this.countPowerMovesToday(worldId, userId);
    const skus = await this.activeSkus(userId);
    return Math.max(0, dailyPowerMoveAllowance(skus) - used);
  }

  // ---- agendas ----
  async setAgenda(worldId: string, userId: string, intentText: string): Promise<void> {
    const myDouble = await this.requireDouble(userId);
    const world = await this.getWorld(worldId);
    if (!world) throw new RepoError('world not found', 404);
    const targetEpisode = world.currentEpisode + 1;
    // One pending agenda per double per target episode.
    await this.sb
      .from('agendas')
      .delete()
      .eq('world_id', worldId)
      .eq('double_id', myDouble.id)
      .eq('target_episode', targetEpisode)
      .eq('status', 'pending');
    must(
      await this.sb
        .from('agendas')
        .insert({
          world_id: worldId,
          double_id: myDouble.id,
          target_episode: targetEpisode,
          intent_text: intentText,
        })
        .select('id'),
    );
    await this.audit(userId, 'set_agenda', worldId, { targetEpisode });
  }

  // ---- markets & bets ----
  async getOpenMarkets(worldId: string): Promise<Market[]> {
    const rows = must(
      await this.sb.from('markets').select('*').eq('world_id', worldId).eq('status', 'open'),
    ) as Record<string, unknown>[];
    return rows.map(mapMarket);
  }

  async placeBet(
    worldId: string,
    userId: string,
    marketId: string,
    optionKey: string,
    stakeClout: number,
  ): Promise<Bet> {
    const { data: marketRow } = await this.sb.from('markets').select('*').eq('id', marketId).maybeSingle();
    if (!marketRow) throw new RepoError('market not found', 404);
    const market = mapMarket(marketRow);
    if (market.status !== 'open') throw new RepoError('market is not open', 409, 'market_closed');
    if (!market.options.some((o) => o.key === optionKey)) {
      throw new RepoError('invalid option', 400, 'bad_option');
    }
    const balance = await this.getClout(worldId, userId);
    if (!canAffordBet(balance, stakeClout)) throw new RepoError('insufficient clout', 409, 'insufficient_clout');

    // Deduct the stake now; resolution credits winners.
    await this.adjustCloutDirect(userId, worldId, -stakeClout);
    const bet = mapBet(
      must(
        await this.sb
          .from('bets')
          .insert({
            world_id: worldId,
            user_id: userId,
            market_id: marketId,
            option_key: optionKey,
            stake_clout: stakeClout,
          })
          .select('*')
          .single(),
      ) as Record<string, unknown>,
    );
    await this.audit(userId, 'place_bet', worldId, { marketId, optionKey, stakeClout });
    return bet;
  }

  /** The caller's bets in a world, enriched with market question + option label + payout. */
  async myBets(worldId: string, userId: string): Promise<EnrichedBet[]> {
    const rows = must(
      await this.sb
        .from('bets')
        .select('*')
        .eq('world_id', worldId)
        .eq('user_id', userId)
        .order('created_at', { ascending: false }),
    ) as Record<string, unknown>[];
    if (rows.length === 0) return [];
    const marketIds = [...new Set(rows.map((r) => r.market_id as string))];
    const markets = (
      must(await this.sb.from('markets').select('*').in('id', marketIds)) as Record<string, unknown>[]
    ).map(mapMarket);
    return rows.map((r) => {
      const market = markets.find((m) => m.id === (r.market_id as string));
      const option = market?.options.find((o) => o.key === (r.option_key as string));
      const stake = r.stake_clout as number;
      return {
        id: r.id as string,
        marketId: r.market_id as string,
        marketQuestion: market?.question ?? 'a market',
        optionLabel: option?.label ?? (r.option_key as string),
        stake,
        status: r.status as Bet['status'],
        potentialPayout: Math.floor(stake * (market?.multiplier ?? 2)),
      };
    });
  }

  // ---- power moves ----
  async spendPowerMove(
    worldId: string,
    userId: string,
    type: string,
    targetDoubleId: string | null,
    payload: Record<string, unknown>,
  ): Promise<void> {
    const used = await this.countPowerMovesToday(worldId, userId);
    const skus = await this.activeSkus(userId);
    if (!canSpendPowerMove(used, skus)) {
      throw new RepoError('daily power-move allowance reached', 429, 'allowance_reached');
    }
    const world = await this.getWorld(worldId);
    if (!world) throw new RepoError('world not found', 404);
    must(
      await this.sb
        .from('power_moves')
        .insert({
          world_id: worldId,
          user_id: userId,
          type,
          target_double_id: targetDoubleId,
          payload,
          apply_on_episode: world.currentEpisode + 1,
        })
        .select('id'),
    );
    await this.audit(userId, 'power_move', worldId, { type, targetDoubleId });
  }

  async countPowerMovesToday(worldId: string, userId: string): Promise<number> {
    const startOfDay = new Date();
    startOfDay.setUTCHours(0, 0, 0, 0);
    const { count } = await this.sb
      .from('power_moves')
      .select('id', { count: 'exact', head: true })
      .eq('world_id', worldId)
      .eq('user_id', userId)
      .gte('created_at', startOfDay.toISOString());
    return count ?? 0;
  }

  // ---- episodes & recaps (with reveal gating) ----
  async getEpisodeView(
    worldId: string,
    number: number,
    userId: string,
  ): Promise<{ number: number; status: string; headline: string | null; beats: BeatView[] } | null> {
    const { data: epRow } = await this.sb
      .from('episodes')
      .select('*')
      .eq('world_id', worldId)
      .eq('number', number)
      .maybeSingle();
    if (!epRow) return null;
    const beats = (
      must(await this.sb.from('beats').select('*').eq('episode_id', epRow.id as string)) as Record<
        string,
        unknown
      >[]
    ).map(mapBeat);

    const hasSub = (await this.activeSkus(userId)).includes('sub_monthly');
    const unlocked = new Set(await this.unlockedBeatIds(userId, beats.map((b) => b.id)));

    const views: BeatView[] = beats.map((b) => {
      const locked = b.visibility === 'reveal_gated' && !hasSub && !unlocked.has(b.id);
      return { ...b, content: locked ? null : b.content, locked } satisfies BeatView;
    });
    return {
      number: epRow.number as number,
      status: epRow.status as string,
      headline: (epRow.headline as string) ?? null,
      beats: views,
    };
  }

  async getLatestRecap(worldId: string, userId: string): Promise<{
    episodeId: string;
    narrative: string;
    highlights: string[];
    gatedBeatIds: string[];
  } | null> {
    // latest published episode for the world
    const { data: ep } = await this.sb
      .from('episodes')
      .select('id, number')
      .eq('world_id', worldId)
      .eq('status', 'published')
      .order('number', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (!ep) return null;
    const { data: recap } = await this.sb
      .from('recaps')
      .select('*')
      .eq('episode_id', ep.id as string)
      .eq('user_id', userId)
      .maybeSingle();
    if (!recap) return null;
    return {
      episodeId: recap.episode_id as string,
      narrative: recap.narrative as string,
      highlights: (recap.highlights as string[]) ?? [],
      gatedBeatIds: (recap.gated_beat_ids as string[]) ?? [],
    };
  }

  // ---- entitlements & reveals ----
  async getEntitlements(userId: string): Promise<Entitlement[]> {
    const rows = must(
      await this.sb.from('entitlements').select('*').eq('user_id', userId),
    ) as Record<string, unknown>[];
    return rows.map((r) => ({
      id: r.id as string,
      userId: r.user_id as string,
      sku: r.sku as EntitlementSku,
      status: r.status as Entitlement['status'],
      source: r.source as Entitlement['source'],
      expiresAt: (r.expires_at as string) ?? null,
      createdAt: r.created_at as string,
    }));
  }

  async grantEntitlement(userId: string, sku: EntitlementSku, source: Entitlement['source']): Promise<void> {
    await this.ensureUser(userId);
    must(
      await this.sb
        .from('entitlements')
        .insert({ user_id: userId, sku, source, status: 'active' })
        .select('id'),
    );
    await this.audit(userId, 'grant_entitlement', null, { sku, source });
  }

  async activeSkus(userId: string): Promise<EntitlementSku[]> {
    const now = new Date().toISOString();
    const rows = must(
      await this.sb.from('entitlements').select('sku, expires_at').eq('user_id', userId).eq('status', 'active'),
    ) as { sku: EntitlementSku; expires_at: string | null }[];
    return rows.filter((r) => !r.expires_at || r.expires_at > now).map((r) => r.sku);
  }

  async unlockReveal(userId: string, beatId: string, source: 'subscription' | 'consumable'): Promise<Beat> {
    const { data: beatRow } = await this.sb.from('beats').select('*').eq('id', beatId).maybeSingle();
    if (!beatRow) throw new RepoError('beat not found', 404);
    must(
      await this.sb
        .from('reveal_unlocks')
        .upsert({ user_id: userId, beat_id: beatId, source }, { onConflict: 'user_id,beat_id' })
        .select('id'),
    );
    await this.audit(userId, 'reveal_unlock', beatRow.world_id as string, { beatId });
    return mapBeat(beatRow); // returns the real stored content (brief §9: only real data)
  }

  private async unlockedBeatIds(userId: string, beatIds: string[]): Promise<string[]> {
    if (beatIds.length === 0) return [];
    const rows = must(
      await this.sb.from('reveal_unlocks').select('beat_id').eq('user_id', userId).in('beat_id', beatIds),
    ) as { beat_id: string }[];
    return rows.map((r) => r.beat_id);
  }

  // ---- helpers ----
  private async requireDouble(userId: string): Promise<Double> {
    const d = await this.getMyDouble(userId);
    if (!d) throw new RepoError('create your double first', 409, 'no_double');
    return d;
  }

  private async enforceConcurrentWorldLimit(userId: string): Promise<void> {
    const myDouble = await this.getMyDouble(userId);
    if (!myDouble) return;
    const { count } = await this.sb
      .from('world_members')
      .select('id', { count: 'exact', head: true })
      .eq('double_id', myDouble.id)
      .eq('status', 'active');
    const skus = await this.activeSkus(userId);
    if ((count ?? 0) >= concurrentWorldLimit(skus)) {
      throw new RepoError('concurrent world limit reached — subscribe for more', 402, 'world_limit');
    }
  }

  private async adjustCloutDirect(userId: string, worldId: string, delta: number): Promise<void> {
    const balance = (await this.getClout(worldId, userId)) + delta;
    await this.sb
      .from('clout_balances')
      .upsert({ user_id: userId, world_id: worldId, balance }, { onConflict: 'user_id,world_id' });
  }

  /** Register an APNs/device push token for the user (idempotent on token). */
  async savePushToken(userId: string, token: string, platform: string): Promise<void> {
    await this.ensureUser(userId);
    must(
      await this.sb
        .from('device_tokens')
        .upsert(
          { user_id: userId, token, platform, updated_at: new Date().toISOString() },
          { onConflict: 'token' },
        )
        .select('id'),
    );
  }

  async recordModeration(
    subjectType: 'persona' | 'beat',
    subjectId: string,
    verdict: 'ok' | 'blocked',
    reason?: string,
  ): Promise<void> {
    await this.sb
      .from('moderation_events')
      .insert({ subject_type: subjectType, subject_id: subjectId, verdict, reason: reason ?? null });
  }

  async audit(
    userId: string | null,
    action: string,
    worldId: string | null,
    metadata: Record<string, unknown>,
  ): Promise<void> {
    await this.sb.from('audit_log').insert({ user_id: userId, action, world_id: worldId, metadata });
  }
}

function cryptoToken(): string {
  // URL-safe random token for invites.
  const bytes = new Uint8Array(18);
  globalThis.crypto.getRandomValues(bytes);
  return Buffer.from(bytes).toString('base64url');
}
