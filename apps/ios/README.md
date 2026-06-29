# Doubles — iOS

The launch client. SwiftUI, iOS 17+, **dark only**. A primetime trash-TV title card: glossy, dark, dramatic, built to be screenshotted. **Wired to the live backend** (Supabase + the Next.js API) — sign in and you walk into a real, seeded season.

## Run the live demo

The app talks to the local API, which runs against the live Supabase project.

1. **Start the API** (from the repo root), pointed at the live DB via `.env`:
   ```bash
   pnpm --filter @doubles/api dev      # http://localhost:3000
   ```
   The demo world ("the group chat", 5 doubles, 3 published episodes) is already seeded in Supabase.
2. **Allow localhost networking (one-time Xcode step).** Because the API is plain `http://localhost`, iOS App Transport Security blocks it by default. In the **Doubles** target → **Info** tab, add **App Transport Security Settings** → **Allow Local Networking = YES** (or set `NSAllowsLocalNetworking` = YES). One checkbox.
3. **Run** on an iOS 17+ simulator (Xcode 16+). On the auth screen, tick **18+** and tap **enter the live demo** — it signs in as the seeded cast (`aria@doubles.dev`) and drops you straight into a populated Today: 3 episodes of real beats, recaps, standings, markets, relationships.

> **Physical device:** localhost won't reach your Mac. Set `DOUBLES_API_BASE_URL` (Info.plist) to your Mac's LAN IP, e.g. `http://192.168.1.20:3000`, and add an ATS exception for that host.

> **Offline / design review:** every `#Preview` and `MockRepository` still work with no backend — the previews don't hit the network. To run the whole app on mock data, swap `RootShell` to inject `MockRepository()` instead of the live gate.

What's live and usable end-to-end: auth + 18+ gate, Today recap + beat feed, **reveal-unlock** a gated beat, **place a bet** and see it in your bets, **spend a power move** (countdown ticks), **set an agenda**, Cast + relationships, Season standings + awards, Settings incl. a real **delete-my-data** path and sign-out. All against the live database.

> **Fonts:** the three brand families (Anton, Bricolage Grotesque — instanced to four static weights, Space Mono) live in `Doubles/Fonts/` and are **registered at runtime** via CoreText in `FontRegistrar` (called from `DoublesApp.init`). No `Info.plist` `UIAppFonts` entry is needed — the synchronized file group copies the `.ttf`s into the bundle automatically. If a glyph renders as the system font, confirm the `Fonts/*.ttf` are in the target's *Copy Bundle Resources*.

> **Heads-up:** this client was authored in an environment **without Xcode**, so it has not been compiled or run in the simulator here. Expect a small first-build fix-up pass (a stray modifier or import). The architecture, design system, fonts, and previews are all in place.

## Architecture

- **`DesignSystem/`** — `DS` tokens (the only place colours/spacing/radii/durations live), the `Font` roles (`.display` / `.ui` / `.mono` + `.monoLabel`), `Color(hex:)`, `ScreenBackground` + `GrainOverlay`, `Haptics`, `FontRegistrar`. **No view hard-codes a hex value or font name.**
- **`Components/`** — the reusable kit: `Chyron` (the signature, with marquee), `PrimaryButton`/`GhostButton` (sharp, not capsules), `DoubleAvatar`/`CharacterCard`, `BeatCard` (post/confessional/twist/ship + locked reveal), `RecapCard` (+ `ImageRenderer` export via `ShareLink`), `StatPill`/`CloutCounter`/`CountUpNumber`, `MarketCard`/`StakeStepper`, `PowerMoveCard`, themed skeleton/empty/error states.
- **`Models/`** — Swift mirrors of `packages/shared` (Codable, ready for the API). The "double" type is `Persona` to avoid the numeric `Double` clash.
- **`Data/`** — `DoublesRepository` protocol with a live `APIRepository` (maps the API/`packages/shared` wire shapes → the UI models, synthesises the tabloid recap fields, computes awards from standings) and a `MockRepository` for previews/offline. `Session` handles Supabase auth over GoTrue REST; `Config` holds the endpoints (anon key only — no server secrets in the client). The live repo is injected by `LiveGate` after sign-in; previews inject `MockRepository.preview`.
- **`Features/`** — Today (hero), Cast + detail, Bets, Season + finale, Onboarding (splash → 18+ gate → build double → create/join → holding), the power-move sheet, agenda sheet, paywall, settings, worlds switcher.

Every screen and major component has a `#Preview` driven by `MockRepository.preview`.

## Design system (committed — do not invent a palette)

Exact tokens in `DesignSystem/DS.swift`: wine `#1B0B12`, plum `#2A0E1F`, surface `#22101A`, magenta `#FF2E74` (down/danger), acid `#E8FF59` (up/success), rose `#C98BA3`, bone `#F6EFE7`. Sharp corners (radius 2) are intentional — pills only for status chips. The **chyron** (magenta lower-third, ink Space Mono) is the recognisable motif: recap card, episode header, twist beats, section markers.

## Safety surfaces (present, by design)

- **18+ age gate** in onboarding blocks every social screen; denial does not proceed.
- **Honest paywall**: clear price + cadence, restore action, and an explicit "cancel anytime — manage in settings". UI only; no real IAP.
- **Real data-deletion path** in Settings → Privacy, behind an explicit confirm that calls `repo.deleteAccount()`.
- Copy never implies the AI activity is real other users. You set an **agenda** and spend **power moves** — you never write your double's actions.

## Accessibility & motion

Dynamic Type (UI/mono scale; display is capped so it never blows the layout), VoiceOver labels on controls (all-caps display strings get lowercase a11y labels), AA contrast on wine, and every animation has a `accessibilityReduceMotion` fallback. Haptics fire on the key actions (episode reveal, bet, power move, reveal unlock, count changes) via `Haptics` / `.sensoryFeedback`.

## Recap export

`RecapCard` renders through `ImageRenderer` at scale 3 (1080×1440) and shares via `ShareLink` from the Today screen — the growth artifact. Fonts are registered before rasterising so the export carries the brand type.
