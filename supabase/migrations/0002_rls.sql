-- =========================================================================
-- Row Level Security (brief §9 — enforce safety in code AND schema).
--
-- Posture: the API is the access path and uses the service-role key, which
-- BYPASSES RLS. We still enable RLS everywhere so that anon/auth clients hitting
-- Postgres directly are denied by default, and we add a small number of explicit
-- policies that bake in the two hard rules:
--   1. A double is editable ONLY by its owner.
--   2. A user can only see/act on their own private rows.
-- =========================================================================

-- Auto-provision a public.users row whenever an auth user is created.
create or replace function handle_new_auth_user() returns trigger as $$
begin
  insert into public.users (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_auth_user();

-- Enable RLS on every table. Default with no policy = deny for anon/auth.
do $$
declare t text;
begin
  foreach t in array array[
    'users','doubles','worlds','world_members','relationships','agendas',
    'episodes','beats','recaps','markets','bets','power_moves','clout_balances',
    'season_scores','entitlements','reveal_unlocks','moderation_events',
    'audit_log','world_invites'
  ] loop
    execute format('alter table %I enable row level security;', t);
  end loop;
end $$;

-- A user may read and update only their own user row.
create policy users_self_select on users for select using (auth.uid() = id);
create policy users_self_update on users for update using (auth.uid() = id);

-- HARD RULE: a double is created/edited ONLY by its owner. No path exists to
-- author another user's persona — there is simply no policy permitting it.
create policy doubles_owner_select on doubles for select using (auth.uid() = owner_user_id);
create policy doubles_owner_insert on doubles for insert with check (auth.uid() = owner_user_id);
create policy doubles_owner_update on doubles for update using (auth.uid() = owner_user_id);
create policy doubles_owner_delete on doubles for delete using (auth.uid() = owner_user_id);

-- Users see their own private game rows directly if they ever query Postgres.
create policy bets_owner_select on bets for select using (auth.uid() = user_id);
create policy power_moves_owner_select on power_moves for select using (auth.uid() = user_id);
create policy clout_owner_select on clout_balances for select using (auth.uid() = user_id);
create policy recaps_owner_select on recaps for select using (auth.uid() = user_id);
create policy entitlements_owner_select on entitlements for select using (auth.uid() = user_id);
create policy reveal_unlocks_owner_select on reveal_unlocks for select using (auth.uid() = user_id);
