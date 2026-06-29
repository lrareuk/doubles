# Doubles

**Tomodachi Life crossed with an AI social sim — multiplayer, with your real friend group.**

Each user authors a *double* of themselves: a self-written character with a personality. You invite friends; their doubles join a shared **world** (a season). The doubles then act autonomously. Every night the engine generates an **episode** in which the doubles post, argue, flirt, scheme, form alliances and fall out — all in character. In the morning each user gets a personalized recap of what their double did.

On top of the autonomous sim, players run a meta-game: set your double's **agenda**, bet a non-cashable currency (**clout**) on what the world will do, and spend a daily allowance of **power moves** to nudge the story. Seasons run a few weeks and end with an awards finale, then reset.

> The novel part — and what the architecture protects — is **autonomy + real friends + the user as audience and coach, never puppeteer**. Users never directly write their double's actions. They influence, then find out what happened.

This repository is the **starting framework**: a runnable, headless backend with a working simulation engine, the core API, the game logic, safety/consent enforcement, monetization scaffolding, and a SwiftUI iOS client skeleton.

---

## Why it's built this way

Two economic facts drive the design:

- **Heavy generation is asynchronous and overnight**, so it runs on the **Batch API** at half price, mostly on the cheap model (Haiku for beats/recaps, Sonnet for planning). This is the product hook *and* the cost control.
- **The only expensive on-demand verb is the power move**, because it triggers generation. Everything else (watching, betting, setting agendas) is cheap or free — so metering is natural: you gate power, not basic fun.

The simulation engine is a **pure, dependency-injected TypeScript package** with the AI behind an interface. It runs end-to-end with **no API key** using a deterministic mock, which is also how the CI/unit tests exercise the whole nightly loop.

---

## Repository structure

```
doubles/
  apps/
    api/        # Next.js (App Router) route handlers + /jobs endpoints  → Vercel
    ios/        # SwiftUI app (Swift) — primary client, Phase 2
  packages/
    engine/     # simulation engine, pure TS, AI behind an interface (+ in-memory test adapter)
    db/         # Supabase-backed Db adapter + API repository, typed mappers
    shared/     # zod schemas, domain types, constants — the canonical API contract
  supabase/
    migrations/ # SQL schema + RLS
    seed/       # seed script: one demo world with 5 doubles
    cron.sql    # nightly Cron template (run by hand after deploy)
```

**Dependency direction:** `shared` ← `engine` ← `db` ← `api`. The engine never imports a framework or Supabase; it talks to injected ports (`Db`, `AIClient`, `Moderator`, `Notifier`, `Clock`, `Logger`).

---

## The nightly loop (engine pipeline)

`runEpisode(worldId)` orchestrates nine individually-testable stages, with an idempotency guard so re-running a published episode is a no-op:

1. **gather** — load doubles, agendas, relationship graph, recent episode summaries, queued power moves → a compact, token-bounded context.
2. **planEpisode** *(Sonnet)* — one structured call returns the beat plan, agenda outcomes, relationship deltas, consumed power moves, proposed markets, and market resolutions. Validated against a zod schema.
3. **generateBeats** *(Haiku, Batch API)* — many cheap in-character generations; the cast block is prompt-cached across calls.
4. **moderate** — every generated beat passes the `Moderator`. Blocked beats are dropped; every decision is logged to `moderation_events`.
5. **applyState** — relationship affinities (clamped), agenda outcomes, beats, proposed markets, power-move consumption.
6. **resolveBets** — settle markets due this episode using the plan's machine-checkable resolution tags. **Deterministic, no AI.**
7. **score** — update season scores (drama / ships / glow-up / villain); on the final episode, set the season to `finale`.
8. **buildRecaps** — per user, assemble a recap from beats involving their double; reference reveal-gated beats by id only (never their content).
9. **notify** — enqueue notifications via the `Notifier` (mock logs; real push deferred). Only ever for an episode that actually published.

---

## Quick start (no Anthropic key required)

### 0. Prerequisites
- Node ≥ 20, **pnpm 9**
- For the live database: the [Supabase CLI](https://supabase.com/docs/guides/cli) (`brew install supabase/tap/supabase`) and Docker, **or** a hosted Supabase project.

### 1. Install
```bash
pnpm install
```

### 2. Environment
```bash
cp .env.example .env
```
The defaults run with **`AI_PROVIDER=mock`** and **no Anthropic key**. Fill in the Supabase values (local defaults are pre-filled in `.env.example`).

### 3. Database: migrations + seed
Start a local Supabase stack (or point `.env` at a hosted project), then apply the schema and seed:
```bash
# local stack
supabase start
supabase db reset            # applies supabase/migrations/*

# seed one demo world with 5 doubles, relationships, starting clout
pnpm seed
# → prints WORLD_ID=...
```
> The seed is **idempotent** — safe to run repeatedly. It drives the same `@doubles/db` code paths the API uses (creates auth users, age-verifies, authors doubles, creates a world, invites + joins).

### 4. Run an episode for the seed world
```bash
pnpm --filter @doubles/api run-episode <WORLD_ID>
```
This runs the full engine against the database: plans the episode, generates + moderates beats, applies relationship/agenda changes, resolves due bets, updates scores, and writes a personalized recap per user — all with the mock AI.

### 5. Start the API
```bash
pnpm --filter @doubles/api dev      # http://localhost:3000
curl http://localhost:3000/health
```
The same engine is reachable over HTTP at `POST /jobs/run-episode/:worldId` (protected by `JOB_SECRET`).

### 6. Tests
```bash
pnpm test           # all packages
pnpm --filter @doubles/engine test   # game-logic units + episode integration test
```

---

## Switching to real Claude

Set in `.env`:
```bash
AI_PROVIDER=claude
ANTHROPIC_API_KEY=sk-ant-...        # server-side only — NEVER commit this
```
The same flow now runs against real Claude: **Haiku** for beats, **Sonnet** for planning, the **Batch API** for nightly generation (`DOUBLES_USE_BATCH=true`), and **prompt caching** for the stable cast block. Model routing is overridable via `DOUBLES_MODEL_PLAN` / `DOUBLES_MODEL_BEAT` / `DOUBLES_MODEL_RECAP`.

> ⚠️ A real Anthropic key was shared in plaintext during scaffolding — **rotate it** at <https://console.anthropic.com/settings/keys> before use. Keys live only in `.env` (gitignored) and are read server-side.

---

## Nightly scheduling (Supabase Cron)

`supabase/cron.sql` is a template that uses `pg_cron` + `pg_net` to POST to `/jobs/run-episode/:worldId` for every active world, authenticated with the job secret from Supabase Vault. Run it once by hand after deploying the API (it embeds your deployed URL + secret, so it's intentionally not an auto-applied migration).

---

## API surface

All input is validated with **zod**; all AI calls happen **server-side only**; every social route is gated on `age_verified`. Auth is a Supabase JWT (`Authorization: Bearer <token>`).

| Method | Route | Purpose |
|---|---|---|
| POST | `/me/age-verify` | Record adult age assurance (vendor stubbed) |
| POST | `/doubles` | Create/update **your own** double (persona moderated first) |
| GET / DELETE | `/doubles/me` | Read / **hard-delete** your double (instant removal) |
| POST | `/worlds` | Create a season |
| POST | `/worlds/:id/invite` · `/join` | Invite token / join (seeds neutral relationships) |
| GET | `/worlds/:id` | World state, standings, my double, clout, power moves left |
| GET | `/worlds/:id/episodes/:n` | Episode beats (gated items locked) |
| GET | `/worlds/:id/recap/latest` | My personalized recap |
| POST | `/worlds/:id/agenda` | Set my double's intent for next episode |
| GET / POST | `/worlds/:id/markets` · `/bets` | Open markets / stake clout |
| POST | `/worlds/:id/power-moves` | Spend a power move (metered) |
| GET | `/worlds/:id/clout` · `/scores` | Balances / standings |
| GET | `/me/entitlements` | Active entitlements |
| POST | `/iap/validate` | Validate receipt → grant entitlement (mock validator) |
| POST | `/reveals/:beatId/unlock` | Reveal a gated beat (real stored content only) |
| POST | `/jobs/run-episode/:worldId` | Run the engine (job-secret protected; Cron) |

---

## Safety, consent & legal (enforced in code)

These are part of the definition of done, not just docs:

- **Adults only.** Every social route requires `age_verified`. There is no under-18 path. The age-assurance vendor is a clearly marked seam.
- **Self-authored doubles only.** No endpoint, ever, lets one user author or edit another's persona. RLS additionally enforces owner-only access to `doubles`.
- **Instant removal.** `DELETE /doubles/me` hard-deletes the double; cascades purge memberships, relationships, agendas, scores and queued power moves.
- **Moderation pipeline.** Every generated beat and every persona input passes the `Moderator` before it is shown or saved; every decision is logged to `moderation_events`. *The scaffold ships a rule-based `MockModerator` — it is a placeholder, not a real safety classifier, and the copy does not overstate it.*
- **Honest mechanics & billing.** Reveal endpoints surface only real stored data; no fabricated content, senders, or notifications. The paywall states recurring terms, price, cadence, and cancellation.
- **Clout is non-cashable.** No path exists to withdraw it or convert it to money.
- **Secrets server-side only.** `.env.example` holds placeholders; nothing secret is committed.
- **UK posture.** A working deletion path (UK GDPR) and seams for Online Safety Act duties.

---

## iOS client

`apps/ios` is a SwiftUI app (the primary, Phase-2 client). It mirrors the `packages/shared` contract as Codable models and talks to the API with a typed networking layer and Supabase auth. See `apps/ios/README.md`. *Xcode was not available during scaffolding, so the Swift sources are written but uncompiled — expect a minor fix-up pass when first opened in Xcode.*

Android (React Native / Expo) is a **later** pass against the same API and shared types — deliberately out of scope here.

---

## Conventions

- Strict TypeScript, no `any` in `engine`/`shared`. All API input and AI output validated with zod.
- The engine core has no framework/DB imports — dependencies are injected, which is what makes it unit-testable.
- Migrations for every schema change; the seed is safe to re-run.
- Conventional commits; small, coherent modules.

## Regenerating DB types

After applying migrations to a hosted project:
```bash
SUPABASE_PROJECT_REF=<ref> pnpm db:types   # → packages/db/src/generated.ts
```
