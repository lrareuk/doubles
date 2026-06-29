# Doubles — Onboarding Spec

> **North star (activation):** a user who has (1) authored a double, (2) joined or created a world, and (3) opted into the morning push.
> Everything below is sequenced to drive all three — in that order — by putting *value before friction* and engineering one undeniable delight beat: **watching your double do something on its own, before you've committed anything.**

This spec is opinionated and tailored to the code already in `apps/ios/Doubles`. It explicitly **replaces** the current cold-open flow (`OnboardingFlow.swift`) and the one-tap age gate in both `OnboardingFlow.AgeGateView` and `AuthView.gate`, which are the exact non-compliant patterns the research flags (single-tap "i'm 18+"). See **§ What changes vs. the current build**.

Brand voice is locked: dark, glossy, tabloid title-card, gen-z, **lowercase-casual**. Design tokens (`DS.swift`), fonts (Anton / Bricolage / Space Mono), and the `Chyron` component are reused verbatim.

---

## The core insight

Doubles is a network-effect product, but a brand-new user is *frequently the first in their group*. A multiplayer-only first run = an instant "zero" (the BeReal / Locket failure mode). So the flow must:

1. **Open straight into authoring the double** — no signup wall, no age wall first. This is the aha and it shows off the voice.
2. **Manufacture a preview "episode" during onboarding** — seed the user's brand-new double with 2–3 AI "house" doubles so they watch a tabloid card of their double *posting / scheming* before any friend exists. This converts the empty network into the delight beat.
3. **Only then** charge the heavier asks, each tied to a payoff that's now visible: **commit (auth + neutral 18+ DOB) → create/join a world → soft-ask the push → invite at peak excitement.**

The autonomous-double reveal is the climax that *earns* the signup. It is never gated behind it.

---

## Screen flow (text diagram)

```
 ┌──────────────────────────────────────────────────────────────────────────┐
 │  VALUE FIRST  (no account, no permissions, guest/local state)            │
 └──────────────────────────────────────────────────────────────────────────┘

  0. COLD OPEN ─────────► 1. BUILD YOUR DOUBLE ─────────► 2. THE FIRST BEAT
     1 tabloid card          name · @handle · the brief        your double's
     "get in"                traits · colour · avatar          autonomous post
     (skippable hook)        live preview, IKEA-effect         (THE AHA)
        │                         │                                 │
        │                         │  (guest/local — nothing saved   │
        │                         │   to a server yet)              │
        ▼                         ▼                                 ▼
 ┌──────────────────────────────────────────────────────────────────────────┐
 │  EARN THE RIGHT TO ASK  (commit point — value already felt)              │
 └──────────────────────────────────────────────────────────────────────────┘

  3. SAVE / CLAIM @HANDLE ──► 3a. NEUTRAL 18+ DOB ──► 4. CREATE OR JOIN A WORLD
     Sign in w/ Apple (1st)      month + year, no       start a season (pick vibe)
     Google · email             pre-fill, blocks <18      OR paste invite code
     "lock your double in"      "this gets messy"            │
        │                          │                          │
        │   guest double migrates  │                          │  first-in-group?
        ▼   to the real account    ▼                          ▼  → seeded house cast
 ┌──────────────────────────────────────────────────────────────────────────┐
 │  SECURE THE RETENTION LOOP, THEN GO VIRAL                                │
 └──────────────────────────────────────────────────────────────────────────┘

  5. PUSH SOFT-ASK ───────► 6. INVITE THE GROUP ───────► 7. HOLDING / "YOU'RE IN"
     mock tabloid push card     one-tap share sheet         "first episode tonight"
     "wake me with the recap"   into group chats            → into the app (Today)
     YES → native iOS prompt    framed as upgrade,          (push re-ask later, tied
        │                       never a wall                 to first real recap)
        ▼                          ▼                          ▼
     [ACTIVATED: double + world + push opt-in]
```

**Pacing rule:** never stack two hard asks back-to-back. Each ask (auth, 18+, push, invite) is separated by a value beat or a tap of forward progress.

---

## Screen-by-screen

### 0 · Cold open (1 card, skippable)
- **Goal:** land the unusual concept in one sentence; get them to "get in" fast.
- **Sees:** one full-bleed tabloid title card. `Chyron(label: "now casting", value: "YOUR GROUP CHAT")`, Anton headline, one-line concept, a single CTA. (Reuses the existing `SplashView` content — it's already on-voice.)
- **Asks:** nothing. No account, no age, no permission.
- **Copy:**
  - Headline: `your friends. but ai. living their own lives while you sleep.`
  - Sub: `you don't script them. you build them, nudge them, and wake up to the drama.`
  - CTA: `get in →`
  - Footer (honesty): `the doubles are ai. nobody here speaks for a real person.`
- **Rationale:** BeReal's skippable intro + Duolingo's "value before signup." An unusual concept needs one beat of framing before the playground, but no wall. (Teardown: intro carousel; gradual engagement.)
- **Success signal:** taps **get in** within ~5s (skip rate low).

### 1 · Build your double (the hook, not a form)
- **Goal:** trigger the IKEA effect — make the user *invest* before any commitment.
- **Sees:** the existing `BuildDoubleView` live preview card up top (avatar + name + @handle + trait chips updating as they type). Expressive slots, framed as choices not data entry: **name**, **@handle**, **the brief** (free text), **traits** (chips from the real `traitPool`: instigator, petty genius, main character, chaos flirt, menace…), **accent colour** (the `DS.characters` palette). A light completion cue.
- **Asks:** the double's content only. Still **guest/local** — nothing hits the server.
- **Copy:**
  - Title: `your double`
  - The brief placeholder: `bring yourself to life — who are you in the group chat?`
  - Helper under the brief: `the more you tell us, the more unhinged they get.` *(makes the Hinge causal link visible: richer brief → better episode)*
  - CTA: `bring yourself to life ✨`
- **Rationale:** Replika's "conversations not a form" + Hinge's structured high-investment slots + visible completion. Persona moderation runs on submit (already wired via `repo.runPersonaModeration`), with the kind error already in code: `let's keep it kind. try rewording that.`
- **Success signal:** completes the brief (>~40 chars) and picks ≥1 trait before continuing.

### 2 · The first beat — the autonomous reveal (THE AHA)
- **Goal:** the single most differentiating delight — the user *watches their own double act on its own*, with zero friends, before committing anything. This is the moment that earns every later ask.
- **Sees:** a generated tabloid **beat card** (reuse `BeatCard` / `Chyron`) where their freshly-authored double does something in character — referencing their actual @handle, brief, and traits. Then a second beat: a seeded **house double** reacts (argues / flirts / subtweets), so the double is already *in a scene*. A dramatic chyron: `EP 00 · PREVIEW`.
- **Asks:** nothing — just "this is what tonight looks like."
- **Copy:**
  - Chyron: `now casting · @{handle}`
  - Beat (templated, filled from their inputs), e.g.: `@{handle} just subtweeted the entire group chat. nobody's named. everybody knows.`
  - Reaction beat: `@therapy.bill: "we are NOT doing this again tonight." (they are doing this again tonight.)`
  - Caption: `your double, off the leash. this is a preview — the real thing runs every night.`
  - CTA: `i need to see more →`
- **Rationale:** Tomodachi's "watch your creation behave autonomously" + Character.AI's "tap and it's already interesting" + the cold-start fix (single-player payoff so the app is never a zero). This is the climax of onboarding, deliberately *before* the auth wall (pitfall: never bury the autonomous reveal behind signup).
- **Success signal:** taps **i need to see more** (proceeds to commit). This is the leading indicator of activation.

### 3 · Save your double / claim @handle (the commit point — auth)
- **Goal:** convert the invested guest into a real account, framed as "save what you built," not "register."
- **Sees:** the double they just watched, pinned at the top ("don't lose this"). Auth buttons in HIG order. Reuses `AuthView`'s Apple/Google/email wiring.
- **Asks:** auth. **Sign in with Apple first** (mandatory under Guideline 4.8 because Google is offered; native, lowest-friction, Face ID), then Google, then email. Apple private-relay ("Hide My Email") wired. The local/guest double migrates to the new account so nothing is lost.
- **Copy:**
  - Headline: `save your double before it does something it regrets.`
  - Sub: `lock in @{handle} so it's yours. we only ever get your name + email.`
  - Buttons: `continue with apple` · `continue with google` · `or use email`
  - Reassure (privacy, gen-z trust): `your @handle is public. your email stays yours — use hide my email if you want.`
- **Rationale:** Duolingo "defer registration to the save moment"; gradual engagement (upfront walls turn away up to ~75%); Apple 4.8 compliance + data minimization. The ask lands *after* the aha, so it feels like a small move inside a bigger journey.
- **Success signal:** completes auth (Apple chosen most).

### 3a · Neutral 18+ age gate (DOB entry — immediately after auth)
- **Goal:** legally clean, defensible 18+ assurance — on-brand, not a sterile wall.
- **Sees:** a **neutral date-of-birth entry** (month + year minimum; no pre-fill, no default that nudges toward 18), styled in the dark/tabloid aesthetic. Computes 18+ from the entered DOB; **blocks** under-18s (hard stop, no self-affirm-through).
- **Asks:** DOB. **Not** a one-tap "i'm 18+" button and **not** a checkbox.
- **Copy:**
  - Chyron: `before we start · one question`
  - Headline: `when were you born?`
  - Sub: `doubles is 18+. it gets messy — we have to check for real.`
  - Picker label: `month / year` (empty by default)
  - Blocked state (reuse existing): `come back when you're 18. the storylines aren't for under-18s. we'll be here.`
- **Rationale:** FTC explicitly calls single-tap / pre-filled / "I'm over 18" patterns **non-compliant** (NGL settlement imposed a neutral-gate remedy). This **replaces** the current one-tap gate in `OnboardingFlow.AgeGateView` and the checkbox in `AuthView.gate`. Placed right at account creation: legally clean, and absorbed by an otherwise light pre-value flow. Don't repurpose the DOB for anything but the gate.
- **Success signal:** enters DOB; 18+ passes through, under-18 is blocked.

### 4 · Create or join a world (+ cold-start handling)
- **Goal:** the second activation pillar — a world — without ever blocking on a friend showing up.
- **Sees:** the existing `CreateOrJoinView`: **start a season** (name it + pick a vibe from the real `WorldVibe` set — 🍿 messy, 🌈 wholesome chaos, 😈 villain arc, 🔪 nobody's safe) **OR** paste an invite code to join a friend's world.
- **Asks:** create vs join + (if creating) a name and vibe.
- **First-in-their-group path (critical):** if they create and are solo, **do not** dead-end them. Auto-seed the world with the same house doubles from the preview so tonight's real episode has a cast — the morning recap lands even alone. Make the seeded cast explicit and the invite an *upgrade*, not a paywall:
  - Solo-create copy: `flying solo? we'll drop a few house doubles in so tonight isn't empty. add your real friends whenever — that's when it gets unhinged.`
  - Atomic-network completion goal (Gas-style): `your season really starts when 3 doubles join.`
- **Copy:**
  - Title: `your season`
  - Create CTA: `start a season 🔥`
  - Join helper: `got a code? jump into a friend's season.` · Join CTA: `join →`
- **Rationale:** the central network-effect risk — never gate activation on a friend (Locket's 3.4-star trap). Trello-style seeded empty state + Gas atomic-network goal. Reuses existing view; only adds the seeded-cast reassurance + the "3 doubles" goal.
- **Success signal:** a world exists for the user (created or joined).

### 5 · Push soft-ask (pre-permission primer — then the native prompt)
- **Goal:** secure the **core retention loop** opt-in. iOS shows the native prompt **once**, so the primer is load-bearing.
- **Sees:** a branded soft-ask styled as a **mock tabloid push notification card** — exactly what they'll receive — so the value is concrete. Fired only **after** they have a double *and* a world (and the preview proved what "your double did something" means).
- **Asks:** permission to send the morning recap push. Tapping **yes** triggers `PushManager.shared.requestAuthorization()` (the existing native prompt). If they tap "not now," do **not** fire the native prompt; offer a deep link to Settings later.
- **Copy:**
  - Mock push preview: `DOUBLES · now` → `episode 01 is live 👀 your double did something. tap to see what you started.`
  - Headline: `your double does its worst overnight.`
  - Sub: `want us to wake you with the recap? this is the whole point.`
  - Primary: `yes, wake me 🔔` → fires native prompt
  - Secondary: `not yet`
- **Rationale:** Duolingo contextual priming; benchmarks ~40–45% cold vs ~60–75% primed (up to +30% lift), strongest when the user effectively triggers the ask. Never fire on launch. Re-ask later tied to a real episode cliffhanger if declined.
- **Success signal:** taps **yes, wake me** and grants the OS prompt. **This completes activation.**

### 6 · Invite the group (peak excitement, one tap, never a wall)
- **Goal:** kick off the network effect at the moment of delight — without harming activation (activation is already done by step 5).
- **Sees:** the existing `InviteSheet`: a copyable invite **code** + a native **share sheet** (deep link), framed around the shared experience. Targeted at group chats.
- **Asks:** an optional, benefit-framed share. Skippable.
- **Copy:**
  - Headline: `this is funnier with your actual friends.`
  - Sub: `drag them in. their double joins the season and the drama compounds overnight.`
  - Share text (already in code, on-voice): `i started a season on Doubles 👀 my double is already plotting. join "{world}" before it gets messy — invite code: {CODE}`
  - Skip affordance: `i'll invite them after the first episode`
- **Rationale:** invite at the moment of delight, one tap, relationship-framed (Locket/Gas/Dropbox). Crucially **after** the delight beat and **never** a gate. A *second*, stronger invite nudge runs later — 48–72h post-activation, after the first real morning recap — with a double-sided clout incentive (both inviter + joiner get bonus clout), staying on-theme without touching real money.
- **Success signal:** opens the share sheet / copies the code (bonus; not required for activation).

### 7 · Holding — "you're in"
- **Goal:** set the return expectation that powers the morning loop.
- **Sees:** the existing `HoldingView`: `Chyron("you're in", "FIRST EPISODE TONIGHT")`, then drop into the **Today** screen.
- **Asks:** nothing.
- **Copy:** `your double is settling in. first episode drops tonight.` / `we'll wake the cast up overnight. check back in the morning — that's when it gets good.` / CTA `enter ⚡`
- **Rationale:** sets the contract behind the morning push; closes the loop the soft-ask just opened.
- **Success signal:** enters the app; opens it again next morning (D1 retention).

---

## Decisions, made deliberately

| Ask | When | Why then |
|---|---|---|
| **Auth (Apple-first)** | Step 3, *after* the autonomous-double reveal | Defer registration to the "save your double" commit point; the aha already happened, so the wall feels like a small step (Duolingo). Apple-first satisfies Guideline 4.8. |
| **18+ gate** | Step 3a, immediately after auth, as **neutral DOB** | Legally clean placement at account creation; neutral DOB (not one-tap/checkbox) is the only FTC-compliant pattern. On-brand so it reads as part of the show. |
| **Notifications** | Step 5, *after* double **and** world exist | Push is the retention loop and iOS only prompts once — a soft-ask primer with a mock push card lifts opt-in to ~60–75%. Self-triggered, contextual. |
| **Invite** | Step 6, at peak excitement, **optional** | Network effect kickoff at the delight moment; never a wall (Locket). Activation already secured by step 5, so a skipped invite doesn't tank the funnel. |

---

## First-in-their-group (cold-start) playbook

1. **Preview beat (step 2)** — the double acts autonomously against seeded house doubles before any friend exists → the app is never a "zero."
2. **Seeded season (step 4)** — a solo-created world gets a small house cast so tonight's *real* episode publishes and the morning recap lands alone.
3. **Atomic goal (step 4)** — "your season really starts when 3 doubles join" gives a concrete social target (Gas-style density).
4. **Invite as upgrade (step 6)** — framed as "funnier with your friends," never "invite to unlock."
5. **Second invite nudge (post-activation, 48–72h)** — after the first real recap, double-sided clout reward for inviting.

---

## What changes vs. the current build (`apps/ios/Doubles`)

- **Add step 2 (the autonomous preview beat).** Today's flow goes splash → age → build → create/join → holding with **no** delight beat where the double acts on its own before commitment. This is the single highest-leverage change.
- **Move auth to a save/commit point and migrate the guest double.** Today `AuthView` is a separate entry with the brand hook; reframe it as "save your double / claim @handle" *after* the preview.
- **Replace both one-tap age gates with a neutral DOB entry.** `OnboardingFlow.AgeGateView` uses a single "i'm 18 or older" button; `AuthView.gate` uses an "i'm 18+" checkbox. Both are the FTC-flagged non-compliant patterns — swap for month+year DOB, no pre-fill, hard block under 18.
- **Add the push soft-ask before `PushManager.requestAuthorization()`.** Today there's no contextual primer screen; the native prompt must only fire on an in-app "yes."
- **Surface the seeded-cast reassurance + "3 doubles" goal in `CreateOrJoinView`.** Today create/join doesn't address the solo first-user explicitly.
- **Keep:** `SplashView`, `BuildDoubleView`, `CreateOrJoinView` mechanics, `InviteSheet`, `HoldingView`, all `DS` tokens and `Chyron` — they're already on-voice.

---

## Guardrails (don't break these)

- Never open on a signup/login wall.
- Never fire the native push prompt on launch or before double+world exist.
- Never make the invite a hard gate.
- Never ship a one-tap / pre-filled 18+ gate.
- Never bury the autonomous-double reveal behind auth or a paywall.
- Clout shown anywhere in onboarding stays clearly **non-cashable, simulated, no real prize** (Guideline 5.3).
