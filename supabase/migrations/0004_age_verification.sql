-- =========================================================================
-- Age assurance (Veriff) references. We store ONLY a boolean result + a vendor
-- reference + status — never the selfie, document, or date of birth (UK GDPR
-- data minimisation; Online Safety Act "highly effective age assurance").
-- The age_verified / age_verified_at columns already exist (0001_init.sql).
-- =========================================================================

alter table users add column if not exists age_verification_ref text;
alter table users add column if not exists age_verification_status text not null default 'unverified';

-- Webhook lookups match the Veriff verification.id (idempotent transitions).
create index if not exists users_age_verification_ref_idx on users (age_verification_ref);
