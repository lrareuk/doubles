-- =========================================================================
-- Device push tokens for the morning-recap notification (brief §6 stage 9).
-- The engine's Notifier enqueues per-user; a sender (APNs) reads these tokens.
-- =========================================================================

create table device_tokens (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references users(id) on delete cascade,
  token      text not null unique,
  platform   text not null default 'ios',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on device_tokens (user_id);

alter table device_tokens enable row level security;
-- Users can see their own tokens directly; the server (service role) bypasses RLS.
create policy device_tokens_owner_select on device_tokens for select using (auth.uid() = user_id);
