-- =========================================================================
-- Doubles — initial schema (brief §5).
-- UUID PKs, created_at timestamptz default now(), FKs with sensible cascades.
-- snake_case columns; the @doubles/shared contract uses camelCase and the db
-- package maps between them.
-- =========================================================================

create extension if not exists pgcrypto;

-- ---- enums --------------------------------------------------------------
create type user_status        as enum ('active', 'removed');
create type moderation_status  as enum ('pending', 'ok', 'blocked');
create type world_vibe         as enum ('messy', 'wholesome_chaos', 'villain_arc', 'nobodys_safe');
create type season_status      as enum ('active', 'finale', 'ended');
create type member_role        as enum ('host', 'member');
create type member_status      as enum ('active', 'left', 'removed');
create type relationship_type  as enum ('neutral', 'friend', 'ally', 'crush', 'rival', 'ex');
create type agenda_status      as enum ('pending', 'in_progress', 'succeeded', 'failed');
create type episode_status     as enum ('planning', 'generating', 'moderating', 'published', 'failed');
create type beat_kind          as enum ('post', 'dm', 'scene', 'twist', 'ship');
create type beat_visibility    as enum ('public', 'reveal_gated');
create type market_status      as enum ('open', 'resolved', 'void');
create type bet_status         as enum ('open', 'won', 'lost', 'void');
create type power_move_type     as enum ('whisper', 'rumour', 'sabotage', 'force_encounter', 'spotlight');
create type power_move_status   as enum ('queued', 'applied', 'expired');
create type entitlement_sku    as enum (
  'sub_monthly', 'season_pass', 'consumable_powerpack', 'consumable_cloutpack',
  'consumable_chaositem', 'cosmetic_avatar', 'cosmetic_season_theme', 'cosmetic_recap_card'
);
create type entitlement_status as enum ('active', 'expired');
create type entitlement_source as enum ('subscription', 'season_pass', 'consumable', 'grant');
create type reveal_source      as enum ('subscription', 'consumable');
create type moderation_subject as enum ('persona', 'beat');
create type moderation_verdict as enum ('ok', 'blocked');

-- ---- users --------------------------------------------------------------
-- Mirrors auth.users 1:1 (id = auth uid). Holds app-level state only.
create table users (
  id              uuid primary key,
  age_verified    boolean not null default false,
  age_verified_at timestamptz,
  status          user_status not null default 'active',
  created_at      timestamptz not null default now()
);

-- ---- doubles ------------------------------------------------------------
-- One canonical double per user. Editable ONLY by its owner (brief §9).
create table doubles (
  id                uuid primary key default gen_random_uuid(),
  owner_user_id     uuid not null unique references users(id) on delete cascade,
  display_name      text not null,
  handle            text not null,
  persona_prompt    text not null,
  traits            jsonb not null default '{}'::jsonb,
  avatar_seed       text not null default '',
  moderation_status moderation_status not null default 'pending',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- ---- worlds -------------------------------------------------------------
create table worlds (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  vibe            world_vibe not null default 'messy',
  created_by      uuid not null references users(id) on delete cascade,
  season_number   int not null default 1,
  season_status   season_status not null default 'active',
  current_episode int not null default 0,
  season_ends_at  timestamptz,
  created_at      timestamptz not null default now()
);

create table world_members (
  id        uuid primary key default gen_random_uuid(),
  world_id  uuid not null references worlds(id) on delete cascade,
  double_id uuid not null references doubles(id) on delete cascade,
  role      member_role not null default 'member',
  status    member_status not null default 'active',
  joined_at timestamptz not null default now(),
  unique (world_id, double_id)
);
create index on world_members (world_id);
create index on world_members (double_id);

-- ---- relationships (directed) -------------------------------------------
create table relationships (
  id             uuid primary key default gen_random_uuid(),
  world_id       uuid not null references worlds(id) on delete cascade,
  from_double_id uuid not null references doubles(id) on delete cascade,
  to_double_id   uuid not null references doubles(id) on delete cascade,
  affinity       int not null default 0 check (affinity between -100 and 100),
  type           relationship_type not null default 'neutral',
  updated_at     timestamptz not null default now(),
  unique (world_id, from_double_id, to_double_id),
  check (from_double_id <> to_double_id)
);
create index on relationships (world_id);

-- ---- agendas ------------------------------------------------------------
create table agendas (
  id             uuid primary key default gen_random_uuid(),
  world_id       uuid not null references worlds(id) on delete cascade,
  double_id      uuid not null references doubles(id) on delete cascade,
  target_episode int not null,
  intent_text    text not null,
  status         agenda_status not null default 'pending',
  created_at     timestamptz not null default now()
);
create index on agendas (world_id, target_episode);

-- ---- episodes -----------------------------------------------------------
create table episodes (
  id           uuid primary key default gen_random_uuid(),
  world_id     uuid not null references worlds(id) on delete cascade,
  number       int not null,
  status       episode_status not null default 'planning',
  headline     text,
  token_usage  jsonb,
  generated_at timestamptz,
  published_at timestamptz,
  created_at   timestamptz not null default now(),
  unique (world_id, number)
);

-- ---- beats --------------------------------------------------------------
create table beats (
  id                     uuid primary key default gen_random_uuid(),
  episode_id             uuid not null references episodes(id) on delete cascade,
  world_id               uuid not null references worlds(id) on delete cascade,
  kind                   beat_kind not null,
  participant_double_ids uuid[] not null default '{}',
  content                text not null,
  visibility             beat_visibility not null default 'public',
  moderation_status      moderation_verdict not null default 'ok',
  created_at             timestamptz not null default now()
);
create index on beats (episode_id);
create index on beats (world_id);

-- ---- recaps -------------------------------------------------------------
create table recaps (
  id             uuid primary key default gen_random_uuid(),
  episode_id     uuid not null references episodes(id) on delete cascade,
  user_id        uuid not null references users(id) on delete cascade,
  narrative      text not null,
  highlights     jsonb not null default '[]'::jsonb,
  gated_beat_ids uuid[] not null default '{}',
  created_at     timestamptz not null default now(),
  unique (episode_id, user_id)
);

-- ---- markets ------------------------------------------------------------
create table markets (
  id                  uuid primary key default gen_random_uuid(),
  world_id            uuid not null references worlds(id) on delete cascade,
  episode_opened      int not null,
  question            text not null,
  options             jsonb not null,
  resolves_on_episode int not null,
  multiplier          numeric not null default 2,
  status              market_status not null default 'open',
  winning_option      text,
  created_at          timestamptz not null default now()
);
create index on markets (world_id, status);

-- ---- bets ---------------------------------------------------------------
create table bets (
  id               uuid primary key default gen_random_uuid(),
  world_id         uuid not null references worlds(id) on delete cascade,
  user_id          uuid not null references users(id) on delete cascade,
  market_id        uuid not null references markets(id) on delete cascade,
  option_key       text not null,
  stake_clout      int not null check (stake_clout > 0),
  status           bet_status not null default 'open',
  resolved_episode int,
  created_at       timestamptz not null default now()
);
create index on bets (market_id, status);
create index on bets (user_id, world_id);

-- ---- power moves --------------------------------------------------------
create table power_moves (
  id               uuid primary key default gen_random_uuid(),
  world_id         uuid not null references worlds(id) on delete cascade,
  user_id          uuid not null references users(id) on delete cascade,
  type             power_move_type not null,
  target_double_id uuid references doubles(id) on delete set null,
  payload          jsonb not null default '{}'::jsonb,
  status           power_move_status not null default 'queued',
  apply_on_episode int not null,
  created_at       timestamptz not null default now(),
  applied_at       timestamptz
);
create index on power_moves (world_id, apply_on_episode, status);
create index on power_moves (user_id, world_id, created_at);

-- ---- clout balances -----------------------------------------------------
create table clout_balances (
  user_id  uuid not null references users(id) on delete cascade,
  world_id uuid not null references worlds(id) on delete cascade,
  balance  int not null default 0,
  primary key (user_id, world_id)
);

-- ---- season scores ------------------------------------------------------
create table season_scores (
  id         uuid primary key default gen_random_uuid(),
  world_id   uuid not null references worlds(id) on delete cascade,
  double_id  uuid not null references doubles(id) on delete cascade,
  drama      int not null default 0,
  ships      int not null default 0,
  glowup     int not null default 0,
  villain    int not null default 0,
  updated_at timestamptz not null default now(),
  unique (world_id, double_id)
);

-- ---- entitlements -------------------------------------------------------
create table entitlements (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  sku        entitlement_sku not null,
  status     entitlement_status not null default 'active',
  source     entitlement_source not null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create index on entitlements (user_id, status);

-- ---- reveal unlocks -----------------------------------------------------
create table reveal_unlocks (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  beat_id    uuid not null references beats(id) on delete cascade,
  source     reveal_source not null,
  created_at timestamptz not null default now(),
  unique (user_id, beat_id)
);

-- ---- moderation events --------------------------------------------------
create table moderation_events (
  id           uuid primary key default gen_random_uuid(),
  subject_type moderation_subject not null,
  -- text, not uuid: a beat is moderated by its plan ref (e.g. "ship-1") before
  -- it is inserted and assigned a uuid; persona events store the double id here.
  subject_id   text not null,
  verdict      moderation_verdict not null,
  reason       text,
  created_at   timestamptz not null default now()
);

-- ---- audit log ----------------------------------------------------------
create table audit_log (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references users(id) on delete set null,
  action     text not null,
  world_id   uuid references worlds(id) on delete set null,
  metadata   jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index on audit_log (world_id, created_at);

-- ---- invite tokens (supports POST /worlds/:id/invite + join) ------------
create table world_invites (
  id         uuid primary key default gen_random_uuid(),
  world_id   uuid not null references worlds(id) on delete cascade,
  token      text not null unique,
  created_by uuid not null references users(id) on delete cascade,
  expires_at timestamptz,
  used_at    timestamptz,
  created_at timestamptz not null default now()
);

-- ---- updated_at touch trigger ------------------------------------------
create or replace function set_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger doubles_set_updated_at before update on doubles
  for each row execute function set_updated_at();
