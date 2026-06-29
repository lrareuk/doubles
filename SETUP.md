# Doubles — Live Demo Setup Guide (2026)

Step-by-step, console-by-console instructions to take **Doubles** from the bundled
offline demo to a real, live demo: Supabase Auth (Apple / Google / email), the API
hosted on Vercel, the nightly engine on Supabase Cron, and (optionally) push.

**Your fixed identifiers — keep these handy. They get pasted between consoles a lot.**

| Thing | Value |
|---|---|
| iOS bundle ID | `com.pellar.Doubles` |
| Apple Team ID | `DQ958R6N4A` |
| Supabase project ref | `ctouykgmzmqoabhmlzcq` |
| Supabase URL | `https://ctouykgmzmqoabhmlzcq.supabase.co` |
| Supabase region | eu-west-2 (London) |
| **Supabase Auth callback URL** | `https://ctouykgmzmqoabhmlzcq.supabase.co/auth/v1/callback` |
| OAuth redirect (custom scheme) | `doubles://auth-callback` |
| API repo path | `apps/api` (Next.js App Router) |
| Workspace deps the API builds | `@doubles/shared`, `@doubles/engine`, `@doubles/db` |

> The Supabase Auth callback URL format is always
> `https://<project-ref>.supabase.co/auth/v1/callback`. You will paste this exact
> string into both Apple's Services ID and Google's Web OAuth client.
> ([Supabase: Login with Apple](https://supabase.com/docs/guides/auth/social-login/auth-apple))

**Do this in order.** Sections 2 and 4 (Apple / Google consoles) produce the values
that Sections 1 and 3 (Supabase) consume. The end-of-doc go-live checklist gives the
fastest ordered path.

---

## 1. Supabase Auth — Apple provider

You can only fully complete this **after** Section 2 (it needs the Services ID, Team
ID, Key ID, and the `.p8` key). Do Section 2 first, then come back here.

1. Open the Supabase dashboard → your project (`ctouykgmzmqoabhmlzcq`).
2. Left sidebar → **Authentication** → **Sign In / Providers** (older UIs: **Providers**).
3. Find **Apple** in the provider list and toggle **Enable Sign in with Apple** on.
4. Copy the **Callback URL (for OAuth)** shown in the panel — it is
   `https://ctouykgmzmqoabhmlzcq.supabase.co/auth/v1/callback`. You will register
   this inside Apple's **Services ID** (Section 2, step 4).
5. Fill the fields:
   - **Client IDs** — a comma-separated list of *every* identifier allowed to use
     this project. Put **both**:
     - your **App ID** `com.pellar.Doubles` (required for the **native** id_token
       flow — see the note below), and
     - your **Services ID** (e.g. `com.pellar.Doubles.web`) (required for the **web**
       OAuth flow).
   - **Secret Key (for OAuth)** — paste the ES256 client-secret JWT you generate from
     the `.p8` key (Section 2, step 6). This is only needed for the web OAuth flow.
6. Click **Save**.

> **Native vs. web — this is the key distinction, and it changes what you need.**
> ([Supabase docs](https://supabase.com/docs/guides/auth/social-login/auth-apple),
> [Swift signInWithIdToken](https://supabase.com/docs/reference/swift/auth-signinwithidtoken))
>
> - **Native Sign in with Apple (recommended for iOS).** The system Apple sheet
>   (`ASAuthorizationAppleIDProvider`) returns an **identity token** directly. The app
>   POSTs it to `https://ctouykgmzmqoabhmlzcq.supabase.co/auth/v1/token?grant_type=id_token`
>   (the supabase-swift `signInWithIdToken` call). This path needs **only** the App ID
>   `com.pellar.Doubles` listed in **Client IDs** above — **no Services ID, no `.p8`,
>   no Secret Key.** Generate a **raw nonce**, SHA-256 it into the Apple request, and
>   pass the **raw** nonce to Supabase.
> - **Web OAuth flow** (used if you ever sign in via the browser / `signInWithOAuth`).
>   This path needs the **Services ID**, the **`.p8` key**, and the **Secret Key JWT**.
>   The Secret Key **expires every 6 months** and must be regenerated — set a calendar
>   reminder.
>
> **Minimum for the iOS demo: native flow only.** List `com.pellar.Doubles` in Client
> IDs and you're done with Apple in Supabase. Do the Services ID / `.p8` work only if
> you also want the web flow.

---

## 2. Apple Developer — Sign in with Apple

Console: <https://developer.apple.com/account> → **Certificates, Identifiers & Profiles**.
Make sure the account is on Team **DQ958R6N4A** (top-right team switcher).

### 2a. Enable the capability on the App ID

1. **Identifiers** → click your App ID **`com.pellar.Doubles`** (create it first if it
   doesn't exist: **+** → **App IDs** → **App** → bundle ID `com.pellar.Doubles`).
2. In **Capabilities**, tick **Sign In with Apple**. Leave it as the primary App ID.
3. **Save**.

> For a pure-native iOS app, **this is the only Apple Developer step you strictly
> need.** Steps 2b–2c below are required only for the web OAuth flow.
> ([Apple: Configure Sign in with Apple for the web](https://developer.apple.com/help/account/capabilities/configure-sign-in-with-apple-for-the-web/))

### 2b. Create a Services ID (web flow only)

1. **Identifiers** → **+** → select **Services IDs** → **Continue**.
2. **Description**: `Doubles Web`. **Identifier**: `com.pellar.Doubles.web` (must
   differ from the App ID). **Continue** → **Register**.
   ([Apple: Register a Services ID](https://developer.apple.com/help/account/identifiers/register-a-services-id/))
3. Click the new Services ID to open it, tick **Sign In with Apple**, click
   **Configure**.
4. In the modal:
   - **Primary App ID**: select `com.pellar.Doubles`.
   - **Domains and Subdomains**: `ctouykgmzmqoabhmlzcq.supabase.co`
   - **Return URLs**: `https://ctouykgmzmqoabhmlzcq.supabase.co/auth/v1/callback`
   - **Next** / **Done** → **Continue** → **Save**.

### 2c. Create a Sign in with Apple key (.p8) (web flow only)

1. **Keys** → **+** (Register a New Key).
2. **Key Name**: `Doubles SIWA`. Tick **Sign in with Apple**, click **Configure**,
   choose Primary App ID `com.pellar.Doubles`, **Save**.
3. **Continue** → **Register** → **Download** the `.p8` file. **You can only download
   it once** — store it safely. Note the **Key ID** (10 chars) shown on the page.

### 2d. Values that go into Supabase (web flow)

You need four things to mint the **Secret Key JWT** for Section 1, step 5:

| Value | Where to find it |
|---|---|
| **Team ID** | `DQ958R6N4A` (top-right of the developer portal) |
| **Key ID** | shown when you created the key (or in **Keys**) |
| **Services ID** | `com.pellar.Doubles.web` |
| **`.p8` key file** | downloaded in 2c |

Generate the ES256 JWT (header `kid` = Key ID; claims `iss`=Team ID, `sub`=Services
ID, `aud`=`https://appleid.apple.com`, `iat`=now, `exp`=now+~6 months). The easiest
path: Supabase's dashboard **"Generate a new secret"** helper in the Apple provider
panel accepts the Team ID, Key ID, Services ID, and `.p8` and produces the JWT for
you. Paste the result into **Secret Key (for OAuth)** in Section 1.

---

## 3. Supabase Auth — Google provider

Complete Section 4 first (it produces the Client ID + secret).

1. Supabase dashboard → **Authentication** → **Sign In / Providers** → **Google** →
   toggle **Enable Sign in with Google** on.
2. Copy the **Callback URL (for OAuth)** shown — same
   `https://ctouykgmzmqoabhmlzcq.supabase.co/auth/v1/callback`. You register this in
   Google (Section 4).
3. Paste:
   - **Client IDs** — the **Web client ID** from Section 4b. (Supabase uses the *web*
     client for the server-side callback exchange, even for an iOS app.) If you also
     created an **iOS** OAuth client, add its client ID here too, comma-separated.
   - **Client Secret (for OAuth)** — the **Web client secret** from Section 4b.
4. **(iOS)** Turn on **Skip nonce check** if present — required so Apple/Google's iOS
   token nonce handling doesn't reject the native flow.
   ([Supabase: Login with Google](https://supabase.com/docs/guides/auth/social-login/auth-google))
5. **Save**.

---

## 4. Google Cloud Console

Console: <https://console.cloud.google.com>. Create or select a project (e.g.
"Doubles").

### 4a. OAuth consent screen

1. Left menu → **APIs & Services** → **OAuth consent screen** (or **Google Auth
   Platform** → **Branding** in the newer UI).
2. **User type**: **External** → **Create**.
3. Fill **App name** (`Doubles`), **User support email**, **Developer contact email**.
   Add a **Privacy policy** and **Terms** link if you have them.
4. **Scopes**: the defaults (`email`, `profile`, `openid`) are enough. Save.
5. While the app is in **Testing**, add your Google account(s) under **Test users**,
   or click **Publish app** for open sign-in.
   ([consent screen](https://console.cloud.google.com/apis/credentials/consent))

### 4b. Create the Web OAuth client (for Supabase)

1. **APIs & Services** → **Credentials** → **+ Create Credentials** → **OAuth client
   ID**.
2. **Application type**: **Web application**. **Name**: `Doubles Supabase Web`.
3. **Authorized redirect URIs** → **+ Add URI** →
   `https://ctouykgmzmqoabhmlzcq.supabase.co/auth/v1/callback`
   (this is the single most important value — it must exactly match the Supabase
   callback URL). **Authorized JavaScript origins** can be left empty for the native
   flow.
4. **Create**. Copy the **Client ID** and **Client secret** → paste into Supabase
   Section 3, step 3.
   ([Clients](https://console.cloud.google.com/auth/clients))

### 4c. Create the iOS OAuth client (native)

1. **+ Create Credentials** → **OAuth client ID** → **Application type**: **iOS**.
2. **Name**: `Doubles iOS`. **Bundle ID**: `com.pellar.Doubles`. (App Store ID
   optional until published.)
3. **Create**. Copy this **iOS Client ID** and add it to Supabase's Google **Client
   IDs** list (comma-separated after the web client ID).

### 4d. Summary — what goes where

| Google value | Pasted into |
|---|---|
| Web Client ID + Web Client secret | Supabase → Google → **Client IDs** + **Client Secret** |
| iOS Client ID | Supabase → Google → **Client IDs** (append) |
| Supabase callback URL | Google Web client → **Authorized redirect URIs** |

---

## 5. iOS app configuration (Xcode)

Repo: `apps/ios/Doubles.xcodeproj`. Target: **Doubles**, bundle ID `com.pellar.Doubles`,
team `DQ958R6N4A`.

### 5a. Register the OAuth custom URL scheme

The Google (and any web) OAuth redirect comes back via a custom scheme. Use
`doubles://auth-callback`.

1. Open `apps/ios/Info.plist` and add a `CFBundleURLTypes` array (Xcode: target →
   **Info** tab → **URL Types** → **+**):
   - **Identifier**: `com.pellar.Doubles.auth`
   - **URL Schemes**: `doubles`
2. Resulting `Info.plist` block:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLName</key>
       <string>com.pellar.Doubles.auth</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>doubles</string>
       </array>
     </dict>
   </array>
   ```
   The app passes `doubles://auth-callback` as the `redirectTo` to
   `signInWithOAuth` and hands the returned URL to `ASWebAuthenticationSession`
   (`callbackURLScheme: "doubles"`).

### 5b. Add the Supabase redirect URL to the allow-list

1. Supabase dashboard → **Authentication** → **URL Configuration**.
2. Under **Redirect URLs**, click **Add URL** and add **`doubles://auth-callback`**.
   (Optionally also `doubles://**` to allow any path.) Without this, Supabase rejects
   the redirect.
   ([Supabase: Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls),
   [Native mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking))
3. Set **Site URL** to your production URL if you have one (otherwise leave it; the
   native demo doesn't depend on it).

### 5c. Enable the Sign in with Apple capability

1. Xcode → target **Doubles** → **Signing & Capabilities** tab.
2. Confirm **Team** = `DQ958R6N4A` and automatic signing is on.
3. Click **+ Capability** → **Sign in with Apple**. This writes the entitlement
   `com.apple.developer.applesignin = ["Default"]` into the target's
   `Doubles.entitlements` and links it on Apple's side to the App ID from Section 2a.

### 5d. App Transport Security note

For the **live Vercel** API (HTTPS), no ATS exception is needed — remove the
`NSAllowsArbitraryLoads` block from `Info.plist` for a clean production build. (It's
only there for plain-`http://localhost` dev. See `apps/ios/Info.plist` lines 41-45.)

---

## 6. Hosting the API on Vercel

The API is a Next.js App Router app at `apps/api` inside a pnpm + Turborepo monorepo.
It depends on three workspace packages that must build first: `@doubles/shared`,
`@doubles/engine`, `@doubles/db` (declared `workspace:*` in `apps/api/package.json`;
transpiled via `transpilePackages` in `apps/api/next.config.mjs`).

1. Push the repo to GitHub (Vercel deploys from Git).
2. Vercel dashboard → **Add New…** → **Project** → **Import** the GitHub repo.
3. **Configure Project** screen:
   - **Framework Preset**: **Next.js** (auto-detected).
   - **Root Directory**: click **Edit** → select **`apps/api`**.
     ([Vercel: Deploying Turborepo](https://vercel.com/docs/monorepos/turborepo))
   - Expand the Root Directory section and ensure **"Include source files outside of
     the Root Directory in the Build Step"** is **enabled** — this is what lets the
     build reach the sibling `packages/*` workspace deps. (On for all projects created
     after Aug 2020, but verify.)
     ([Vercel: Monorepos](https://vercel.com/docs/monorepos))
   - **Build Command**: leave default. Vercel runs Turborepo globally; with Root
     Directory = `apps/api` it infers `turbo run build --filter=@doubles/api`, which
     builds `^build` (the workspace deps) first. If you hit a build error, override
     with: `cd ../.. && pnpm turbo run build --filter=@doubles/api`.
   - **Install Command**: leave default — Vercel detects pnpm from `pnpm-lock.yaml`
     and installs the **whole workspace from the repo root**. If overriding, use
     `pnpm install --frozen-lockfile` (no `cd`; Vercel already installs at root for
     workspace projects).
   - **Output Directory**: leave default (Next.js `.next`).
4. **Environment Variables** — add these (Production + Preview). Mark them as needed;
   none are `NEXT_PUBLIC_`, so all stay server-side. Values come from Supabase
   dashboard → **Project Settings → API**:
   | Key | Value / source | Notes |
   |---|---|---|
   | `SUPABASE_URL` | `https://ctouykgmzmqoabhmlzcq.supabase.co` | |
   | `SUPABASE_ANON_KEY` | Supabase → Settings → API → **anon/publishable key** | |
   | `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Settings → API → **service_role key** | **server-only, secret** |
   | `JOB_SECRET` | a long random string you choose | protects `/jobs/run-episode/*`; reused in Section 7 |
   | `AI_PROVIDER` | `mock` for a free deterministic demo, or `claude` for real generation | |
   | `ANTHROPIC_API_KEY` | from <https://console.anthropic.com> | **only** required if `AI_PROVIDER=claude` |

   (Optional tuning vars the API reads: `DOUBLES_MODEL_PLAN`, `DOUBLES_MODEL_BEAT`,
   `DOUBLES_MODEL_RECAP`, `DOUBLES_USE_BATCH`, `DOUBLES_BEAT_CAP`,
   `DOUBLES_TOKEN_BUDGET` — see `apps/api/lib/env.ts`. Defaults are fine.)
5. Click **Deploy**. When it finishes, your **public HTTPS URL** is shown on the
   project's **Production Deployment** (e.g. `https://doubles-api.vercel.app`, or your
   assigned domain under **Settings → Domains**).
6. Verify: open `https://<your-api>.vercel.app/health` in a browser — it should return
   `{"ok":true,"service":"doubles-api","aiProvider":"..."}` (see
   `apps/api/app/health/route.ts`).

> **Note on `maxDuration` (Hobby is fine):** the job route sets `export const maxDuration = 60`
> (`apps/api/app/jobs/run-episode/[worldId]/route.ts`) — the Vercel **Hobby/free** ceiling.
> No Pro plan needed. Episodes finish in <1s on `mock` and well within 60s on synchronous
> Claude (Haiku). The **only** thing that would exceed 60s is the **Batch API**
> (`DOUBLES_USE_BATCH=true`), which polls for minutes — keep that **off** on Hobby
> (use `AI_PROVIDER=mock`, or `claude` with `DOUBLES_USE_BATCH=false`).
> The nightly cron itself runs in **Supabase** (`pg_cron`, free) — not Vercel Cron — so
> Vercel's cron limits don't apply.

---

## 7. Supabase Cron → nightly episodes

Schedule a nightly POST to
`https://<deployed-api>/jobs/run-episode/:worldId` carrying `Authorization: Bearer
<JOB_SECRET>`. The template lives in the repo at **`supabase/cron.sql`** — it uses
**pg_cron** (scheduler) + **pg_net** (`net.http_post`) and reads the secret + API URL
from **Vault** so nothing is inlined.
([Supabase: Schedule Functions](https://supabase.com/docs/guides/functions/schedule-functions),
[Cron quickstart](https://supabase.com/docs/guides/cron/quickstart))

1. Supabase dashboard → **SQL Editor**.
2. Enable extensions (Supabase ships both):
   ```sql
   create extension if not exists pg_cron;
   create extension if not exists pg_net;
   ```
3. Store the deployed API URL and the **same `JOB_SECRET`** you set in Vercel into
   **Vault** (Dashboard → **Project Settings → Vault**, or via SQL):
   ```sql
   select vault.create_secret('https://<your-api>.vercel.app', 'doubles_api_base_url');
   select vault.create_secret('<YOUR_JOB_SECRET>',             'doubles_job_secret');
   ```
4. Paste the rest of `supabase/cron.sql` (the `run_nightly_episodes()` function +
   `cron.schedule('doubles-nightly', '0 3 * * *', ...)`). It loops every world with
   `season_status in ('active','finale')` and POSTs to
   `api_base || '/jobs/run-episode/' || w.id` with the Bearer secret. Runs at **03:00
   UTC** nightly; the endpoint is idempotent so a duplicate fire is safe.
5. Verify the schedule:
   ```sql
   select * from cron.job;                                   -- shows 'doubles-nightly'
   select * from cron.job_run_details order by start_time desc limit 5;  -- run history
   ```
   To remove: `select cron.unschedule('doubles-nightly');`

> Alternatively, the dashboard now has **Integrations → Cron** (a UI over pg_cron) if
> you prefer point-and-click scheduling, but the SQL template is self-documenting and
> matches the repo.

---

## 8. Push notifications (APNs) — the retention loop

This is the viral/retention hook: "**Episode N is live — your double did something.**"
Push when the nightly job publishes an episode. Concise options:

1. **Create the APNs Auth Key (.p8).** Apple Developer → **Keys** → **+** → tick
   **Apple Push Notifications service (APNs)** → **Continue** → **Register** →
   **Download** the `.p8` (once only). Note the **Key ID** and your **Team ID**
   (`DQ958R6N4A`).
   ([Apple Push setup background](https://supabase.com/docs/guides/functions/examples/push-notifications))
2. **Collect device tokens.** In iOS, register for remote notifications and store each
   device's APNs token in a Supabase table (e.g. `device_tokens(user_id, token)`).
   Add the **Push Notifications** capability in Xcode (Signing & Capabilities).
3. **Send.** Two realistic minimums:
   - **Supabase Edge Function → APNs directly.** A Deno Edge Function mints an ES256
     JWT from the `.p8` (Key ID + Team ID) and POSTs to
     `https://api.push.apple.com/3/device/<token>` (topic = `com.pellar.Doubles`).
     Trigger it from the same nightly job (or a DB webhook on episode publish). Store
     the `.p8` contents as an Edge Function **secret**
     (`supabase secrets set APNS_KEY=...`).
   - **Via a provider (lower effort).** Upload the same `.p8` to **Firebase Cloud
     Messaging** (or OneSignal) and have the Edge Function call the provider's HTTP
     API. Firebase Admin credentials stay server-side.
     ([Supabase: Sending Push Notifications](https://supabase.com/docs/guides/functions/examples/push-notifications))

> **Minimum to enable the loop:** APNs `.p8` key + a `device_tokens` table + one Edge
> Function that fires on episode publish. Everything else (rich payloads, deep links
> into the episode) is polish. Skip entirely for a first live demo — auth + live data
> is enough to show.

---

## 9. Go-live checklist (ordered)

Do these in order; each step's output feeds the next.

1. **Vercel** (Section 6): import repo, Root Directory = `apps/api`, set env vars
   (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `JOB_SECRET`,
   `AI_PROVIDER`, + `ANTHROPIC_API_KEY` if `claude`). Deploy. Grab the HTTPS URL and
   confirm `/health` returns ok.
2. **Apple** (Section 2): enable **Sign in with Apple** on App ID `com.pellar.Doubles`.
   (Services ID + `.p8` only if you want the web flow.)
3. **Google** (Section 4): consent screen → **Web** OAuth client (redirect =
   Supabase callback URL) → **iOS** OAuth client (bundle `com.pellar.Doubles`).
4. **Supabase Auth** (Sections 1 & 3): enable **Apple** (Client IDs =
   `com.pellar.Doubles` for native) and **Google** (paste Web client ID + secret;
   add iOS client ID; Skip nonce check on).
5. **Supabase URL config** (Section 5b): add redirect URL **`doubles://auth-callback`**.
6. **Xcode** (Section 5): add the `doubles` URL scheme to `Info.plist`; add the **Sign
   in with Apple** capability; confirm team `DQ958R6N4A`.
7. **Supabase Cron** (Section 7): run `supabase/cron.sql` with Vault holding the
   Vercel URL + the same `JOB_SECRET`.
8. **(Optional) Push** (Section 8): APNs `.p8` + Edge Function.

### The flag that flips the app from offline demo to live

In **`apps/ios/Info.plist`** (currently lines 36-40):

1. Set **`DOUBLES_USE_MOCK`** from `YES` → **`NO`** (case-insensitive; `Config.useMock`
   checks for `"YES"`, so anything else means live — see
   `apps/ios/Doubles/Data/Config.swift:39`).
2. Set **`DOUBLES_API_BASE_URL`** to your Vercel URL, e.g.
   **`https://doubles-api.vercel.app`** (replace the dev LAN IP on line 40).
3. (Optional) Override **`SUPABASE_URL`** / **`SUPABASE_ANON_KEY`** in `Info.plist` if
   they differ from the baked defaults in `Config.swift`. The defaults already point at
   `https://ctouykgmzmqoabhmlzcq.supabase.co`.
4. Remove the `NSAppTransportSecurity` / `NSAllowsArbitraryLoads` block (Section 5d) —
   it's only for plain-http localhost.

Build & run on an iOS 17+ simulator/device. With `DOUBLES_USE_MOCK=NO`, the app uses
`APIRepository` against your live Vercel API + Supabase, real Sign in with Apple /
Google / email, the seeded season, and nightly episodes from Cron.

---

### Sources

- Supabase — Login with Apple: <https://supabase.com/docs/guides/auth/social-login/auth-apple>
- Supabase — Swift `signInWithIdToken` (native): <https://supabase.com/docs/reference/swift/auth-signinwithidtoken>
- Supabase — Login with Google: <https://supabase.com/docs/guides/auth/social-login/auth-google>
- Supabase — Redirect URLs: <https://supabase.com/docs/guides/auth/redirect-urls>
- Supabase — Native Mobile Deep Linking: <https://supabase.com/docs/guides/auth/native-mobile-deep-linking>
- Supabase — Schedule Functions (pg_cron + pg_net + Vault): <https://supabase.com/docs/guides/functions/schedule-functions>
- Supabase — Cron quickstart: <https://supabase.com/docs/guides/cron/quickstart>
- Supabase — Sending Push Notifications: <https://supabase.com/docs/guides/functions/examples/push-notifications>
- Apple — Register a Services ID: <https://developer.apple.com/help/account/identifiers/register-a-services-id/>
- Apple — Configure Sign in with Apple for the web: <https://developer.apple.com/help/account/capabilities/configure-sign-in-with-apple-for-the-web/>
- Vercel — Deploying Turborepo: <https://vercel.com/docs/monorepos/turborepo>
- Vercel — Using Monorepos: <https://vercel.com/docs/monorepos>
- Google Cloud — OAuth consent screen: <https://console.cloud.google.com/apis/credentials/consent>
- Google Cloud — Clients (OAuth credentials): <https://console.cloud.google.com/auth/clients>
