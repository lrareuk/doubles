-- =========================================================================
-- Supabase Cron wiring for the nightly engine (brief §8: "Also wired to
-- Supabase Cron"). This is a TEMPLATE — it is NOT auto-applied by migrations
-- because it embeds your deployed API URL and job secret. Run it once, by hand,
-- in the Supabase SQL editor (or via psql) after you deploy the API.
--
-- It uses pg_cron to schedule and pg_net to POST to the Vercel-hosted job
-- endpoint with the shared job secret. The endpoint itself is idempotent, so a
-- missed/duplicate fire is safe.
-- =========================================================================

-- 1. Enable the extensions (Supabase ships both).
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 2. Store the job secret + API base url in Vault (never inline secrets).
--    Run these once, replacing the placeholder values:
--
--    select vault.create_secret('https://your-api.vercel.app', 'doubles_api_base_url');
--    select vault.create_secret('YOUR_JOB_SECRET',            'doubles_job_secret');

-- 3. A helper that runs an episode for every active world.
create or replace function run_nightly_episodes() returns void as $$
declare
  w record;
  api_base text;
  job_secret text;
begin
  select decrypted_secret into api_base
    from vault.decrypted_secrets where name = 'doubles_api_base_url';
  select decrypted_secret into job_secret
    from vault.decrypted_secrets where name = 'doubles_job_secret';

  for w in select id from worlds where season_status in ('active', 'finale') loop
    perform net.http_post(
      url     := api_base || '/jobs/run-episode/' || w.id,
      headers := jsonb_build_object(
        'content-type', 'application/json',
        'authorization', 'Bearer ' || job_secret
      ),
      body    := '{}'::jsonb
    );
  end loop;
end;
$$ language plpgsql security definer;

-- 4. Schedule it nightly at 03:00 UTC. (Adjust the cron expression as needed.)
select cron.schedule('doubles-nightly', '0 3 * * *', $$select run_nightly_episodes();$$);

-- To remove:  select cron.unschedule('doubles-nightly');
