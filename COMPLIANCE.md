# Doubles — Compliance Action Plan

**Operator:** Pellar Technologies Limited (England & Wales, Newcastle)
**Product:** Doubles — an 18+ AI social-simulation app with user-to-user AI-generated content and an in-app "clout" prediction/betting mechanic
**Prepared by:** Product counsel (synthesis memo)
**Date:** 2026-06-29
**Status:** Pre-launch / live obligations already past on age assurance

> **Important:** This memo informs, but is not a substitute for, sign-off by a solicitor. Two items require external legal sign-off before launch and are flagged explicitly: (1) a UK gambling-law opinion on the clout mechanic, and (2) a data-protection review of the age-assurance vendor arrangement (DPA, transfer mechanism, DPIA). Self-certification is not adequate for either.

---

## 1. Executive summary

Doubles faces three distinct compliance workstreams of differing legal weight:

1. **Age assurance (HIGHEST PRIORITY — legally required, deadline already passed).** The only age control today is a self-declared date-of-birth wheel that sets an `age_verified` boolean. Under the Online Safety Act 2023 and Ofcom's guidance, **self-declaration cannot satisfy "highly effective age assurance" (HEAA)**. Because Doubles markets a strictly 18+ adults-only service with mature/flirtatious AI content, it cannot lawfully conclude that it is "not likely to be accessed by children" and therefore falls into the full Protection of Children regime, whose duties have been live since 25 July 2025 — i.e. **already overdue as of today**. This is the single most urgent item. Required, not advisable.

2. **Privacy/Terms accuracy (HIGH — legally required; live misrepresentation risk).** Codebase verification found that the public-facing claim that personal data is **"encrypted on your device with AES-256-GCM before it reaches our servers" is false** — no client-side encryption exists. The "delete your account and data … purged" claim is **only partly true** — deletion leaves the auth user/email, app `users` row, entitlements, bets, clout balances, and other user-keyed rows in place. Publishing false statements of fact to consumers is a consumer-protection and misrepresentation exposure independent of the OSA. Required to fix before (or immediately at) launch.

3. **Gambling risk on the clout mechanic (MEDIUM — mostly advisable + one required opinion).** On the better view, the clout mechanic falls **outside** licensable gambling under the Gambling Act 2005 because clout is non-cashable and non-transferable (no "money or money's worth" prize). But it is built and marketed in betting language ("bets", "odds", "stake", "payout", "multiplier") and clout is purchasable via IAP, so it sits close to the line. Mitigations are cheap relative to the downside (s.33 unlicensed-gambling offence, app-store removal). A written UK gambling-law opinion on the final design is the one required item here.

**Honest bottom line:** Items 1 and 2 are legal obligations with live exposure now. Item 3 is principally risk management plus one required legal opinion. The cheapest decisive moves — integrate a HEAA vendor, fix the two false policy statements, and keep purchased clout non-stakeable — remove most of the exposure across all three workstreams.

---

## 2. Gambling risk + mitigations

### 2.1 The legal position (honest assessment: probably not licensable, rated MEDIUM)

- **Gaming/betting/lottery under GA 2005 all turn on a prize of "money or money's worth"** (ss.6, 9, 14, 339). The Gambling Commission's 2017 position paper and the DCMS 2022 loot-box response both treat in-game currency as outside the definition **unless it can be cashed out, sold, or traded for real-world value**. Clout is stated to be non-cashable and non-transferable, so on the controlling interpretation the winnings have no money's worth — and the mechanic is **outside** licensable gambling.
- **The legal hinge is the exit, not the entry.** Purchasability of clout does *not* by itself give the prize money's worth — what matters legally is whether winnings can be converted out, not how the currency was funded. So a one-way purchasable currency that can never be converted back to value does not become gambling merely by being bought.
- **Why MEDIUM and not low.** Three facts erode the safe harbour: (1) the mechanic is framed and built as "bets/markets/odds/payouts" with a multiplier (`potentialPayout = stake * multiplier`); (2) clout is purchasable via consumable IAP; and (3) the product brief envisages purchased clout flowing into the same stakeable balance, recreating the "buy chips → wager → win more" loop that regulators, ASA, and the app stores scrutinise. These are precisely the design choices a regulator or store reviewer would seize on.

### 2.2 A helpful finding from the codebase

As currently built, **purchased clout does NOT actually credit the stakeable betting balance.** `grantEntitlement` only inserts an entitlement row for `consumable_cloutpack`; the only writes to `clout_balances` are the starting allowance, the bet deduction, and `adjustCloutDirect`. There is no code path crediting bought clout into `clout_balances`. The brief says clout "can be purchased" and "staked", which diverges from the code. **Resolve this gap in the safe direction: keep purchased clout out of the stakeable balance.** This is the single most decisive mitigation and is mostly a matter of *not* wiring packs into `clout_balances`.

### 2.3 Mitigations (prioritised)

| Priority | Action | Type | Required vs advisable |
|---|---|---|---|
| NOW | **Make purchased clout non-stakeable.** Split into two ledgers — `earned_clout` (stakeable) and `purchased_clout` (spend-only: cosmetics/standing/power moves, never a bet stake). Enforce server-side in `placeBet` (`packages/db/src/repo.ts:353`) by debiting only the earned ledger. | product | Advisable (decisive risk control) |
| NOW | **Guarantee no payout of value.** Hard technical bans on cash-out, P2P/account transfer, trading, and any conversion of clout into refundable IAP value or a second redeemable currency. (Google's 2025 social-casino test auto-classifies as Real-Money Gambling if any "secondary redeemable currency" exists.) No admin/support path that pays out clout for money. | product | Advisable (preserves the "no money's worth" conclusion) |
| NOW | **Obtain a written UK gambling-law legal opinion** on the *final* design (purchased clout non-stakeable, no cash-out, caps, age assurance) confirming no operating licence is required under GA 2005 and no s.33 offence. Keep on file. The legal-data.ts review note (line 309) already flags this — close it with a real opinion, not self-certification. | legal | **REQUIRED — solicitor sign-off essential** |
| SOON | **Add hard spend caps and controls** on clout-pack/power-pack purchases: per-user daily/weekly/monthly net-spend caps, a visible running total, a cool-off/self-exclusion toggle, and a cap-reached block (a "Spending & play controls" screen). | product | Advisable |
| SOON | **Re-frame away from gambling vocabulary** in UI and store copy ("predictions"/"calls"/"standing" rather than "bet/odds/stake/payout/markets"). Internal field names can stay; change player-facing strings. Do NOT boast "not gambling" — state factually that clout has no cash value and cannot be cashed out. | product | Advisable |
| LATER | **Geo-scope the position.** The non-cashout analysis differs by jurisdiction (e.g. Belgium loot-box stance, US state rules). Decide launch territories and geo-restrict where the mechanic could be treated as gambling. | legal | Advisable |
| LATER | **Maintain an internal compliance record** (design + legal basis + citations to GC 2017 paper and DCMS 2022 response) as the evidence pack for a regulator or store challenge. | ops | Advisable |

---

## 3. Age assurance + DOB

### 3.1 The legal position (honest assessment: required; deadline already past — HIGH)

- **Self-declared DOB is legally insufficient.** Ofcom's guidance expressly states self-declaration is *not* highly effective. The current gate (`apps/api/app/me/age-verify/route.ts` → `ageVerify` writing only `age_verified`/`age_verified_at`; iOS `OnboardingFlow.swift` DOB wheel checking `years >= 18` locally) cannot support a "not likely to be accessed by children" conclusion. So HEAA is **required, not optional**, for the 18+ positioning.
- **Doubles is in scope.** It is a UK-operated Part 3 user-to-user service (AI-generated posts other users encounter); the operator is itself UK-based, so scope is unambiguous. The 18+ branding does not exempt it — it *increases* the duty to keep children out.
- **Deadline already passed.** Children's risk-assessment / Protection of Children duties have been enforceable since **25 July 2025**. As of June 2026 this is a **live, overdue obligation**, not a future one.
- **Mature/flirtatious content escalates the duty.** To the extent generated content becomes sexually explicit, it risks being treated as primary priority / pornographic content under s.12 OSA, which carries a *mandatory* HEAA duty. Either route lands on the same answer: deploy HEAA.
- **Enforcement is real:** Ofcom fines up to £18m or 10% of qualifying worldwide revenue, plus business-disruption measures; ICO action is also live for a UK entity.

### 3.2 DOB and data minimisation

- Codebase verification **CONFIRMS** the current design stores only `age_verified` + `age_verified_at`, no `date_of_birth` column; DOB is evaluated on-device and an empty-body POST is sent. That part is good.
- **But the iOS client still captures full DOB**, and for a binary 18+ gate the necessary output is a yes/no adult determination, not a date of birth. Under UK GDPR Art 5(1)(c) (minimisation), Art 25 (by design/default) and the ICO Children's Code, a HEAA vendor should return **only an over-18 boolean** and ideally never transmit document/biometric data to Doubles.
- **Onboarding order is wrong for access control.** Today the flow is coldOpen → build double → aha → auth → age → world, so the user authenticates and authors content *before* the age check. HEAA should gate access to the service **at or before sign-up**, before any mature content or world access.

### 3.3 Mitigations (prioritised)

| Priority | Action | Type | Required vs advisable |
|---|---|---|---|
| NOW | **Integrate a third-party HEAA vendor** returning only an over-18 boolean, gating access at/before sign-up. Reuse the seam at `apps/api/app/me/age-verify/route.ts`. Candidate vendors: Yoti (facial age estimation + ID; strongest UK/Ofcom track record), Persona, Veriff, k-ID. Prefer facial age estimation (no document stored) with ID-match fallback. SDK should run on-device/redirect and return only pass/fail + a reference. | product | **REQUIRED** |
| NOW | **Complete and document a Children's Access Assessment** (Ofcom two-stage test). With HEAA + access controls you can record "not likely to be accessed by children." Keep a dated written record. **Do not back-date or claim compliance for any period when only self-declaration was live.** | ops | **REQUIRED** |
| NOW | **Stop capturing/transmitting full DOB once HEAA is the gate.** Keep `age_verified`/`age_verified_at`; additionally store vendor name, method, and a verification reference for audit — never the DOB, document, or biometric. | product | **REQUIRED (data minimisation)** |
| SOON | **Add the HEAA vendor as a processor:** Art 28 DPA, transfer mechanism (prefer UK/EU; US needs UK IDTA/Addendum), ROPA entry, and a DPIA covering identity/biometric processing (Art 35 + Children's Code). | legal | **REQUIRED — solicitor/DPO sign-off essential** |
| SOON | **Set and document a retention schedule** for age-assurance records: keep only the over-18 result + reference for the account's life; delete on account deletion; bound the vendor's retention contractually. | policy | Required |
| SOON | **Update store ratings.** App Store age rating to 18+ under the post-2025 tiers (questionnaire deadline was 31 Jan 2026); complete Google Play/IARC honestly (UGC, IAP, mature themes). Treat store-level adult confirmation as complementary to — not a replacement for — your own HEAA. | ops | Required (store policy) |
| SOON | **Anti-circumvention.** No in-app content encouraging VPN use to evade checks (Ofcom expectation); bind verified-adult status to the authenticated account, not device-local flags, so reinstalling does not bypass it. | policy | Advisable |
| LATER | **Commission separate gambling/loot-box legal review** of the clout mechanic (see §2 — same opinion). | legal | Required (covered above) |

---

## 4. Privacy/Terms accuracy fixes

Codebase verification checked five public claims. Two are materially false/misleading and must be corrected; the others inform supporting edits.

### 4.1 FALSE — client-side AES-256-GCM encryption (most serious inaccuracy)

- **Claim:** "Your personal data is encrypted on your device with AES-256-GCM before it reaches our servers."
- **Reality:** No AES/GCM/SealedBox/encrypt usage exists anywhere in `apps/ios`. CryptoKit is used *only* for the sign-in nonce/PKCE (`AuthProviders.swift`). PII (display name, @handle, persona/brief, traits) is uploaded as **plaintext JSON over HTTPS** (`APIRepository.swift` `request()`/`upsertDouble()`) and stored as plaintext columns. Protection is TLS in transit + Supabase at-rest only.
- **Fix:** Remove the AES-256-GCM/on-device wording entirely. Replace with accurate language: *"Your connection to our servers is protected with industry-standard TLS encryption, and your data is encrypted at rest by our hosting provider (Supabase)."* Appears in `legal-data.ts` plainSummary (line 8) and is referenced in the Terms (line 786) — both must change.
- **Why it matters:** This is a false statement of fact to consumers — misrepresentation / consumer-protection (CPUTR, CRA 2015) exposure independent of the OSA.

### 4.2 PARTLY TRUE — "delete your account and data … purged"

- **Reality:** In-app deletion (`deleteAccount()` → `deleteMyDoubleAndPurge`) deletes only the `doubles` row and its directly cascaded game rows (world_members, relationships, agendas, season_scores). It does **NOT** delete the auth user (email), the app `users` row (which holds `age_verified`), entitlements, bets, clout_balances, the user's own power_moves, recaps, reveal_unlocks, device_tokens, or audit_log. The repo comment claims beat `uuid[]` participant references are scrubbed, but **no such UPDATE exists**.
- **Fix (choose one):**
  - **(a) Correct the wording** to match reality: *"You can delete your double and its associated game data from inside the app at any time; this happens immediately. To fully delete your account, including your sign-in email and purchase history, contact us at alex@pellar.co.uk and we will erase it."* OR
  - **(b) Implement true deletion** (delete the `users` row + `auth.users` via Supabase admin and the user-keyed rows) so the existing "purged" wording becomes accurate.
- **Why it matters:** UK GDPR Art 17 (erasure) plus an accuracy/misrepresentation issue. Option (b) is the stronger long-term answer.

### 4.3 CONFIRMED claims (no fix needed, but note residual items)

- **Only in-character text sent to Anthropic, never email/DOB/payment** — CONFIRMED by the engine's `gather()`/prompt code. No change needed.
- **DOB self-declared; only `age_verified` flag stored, not full DOB** — CONFIRMED at the DB layer. (Separate issue: self-declaration is inadequate for the OSA — see §3.)

### 4.4 UNKNOWN — Supabase region EU/London (eu-west-2)

- Documented consistently in repo config (SETUP.md, Config.swift, legal-data.ts) but **cannot be verified from code** — region is a Supabase provisioning setting with no infrastructure-as-code pinning it. legal-data.ts line 304 itself notes "Confirm Supabase hosting region as EU/London (eu-west-2) in production."
- **Action:** Verify the live project's actual region in the Supabase dashboard before relying on the EU/London statement; if the live project is elsewhere, either migrate or correct the policy text.

### 4.5 Policy text edits arising from gambling + age workstreams

These flow from §2 and §3 and should be made alongside the accuracy fixes:

- **Terms §8 (Clout):** add an explicit non-stakeability + source-split clause (purchased clout is spend-only and cannot be staked; only free/earned/won clout can be staked; clout has no monetary value and can never be cashed out/transferred/converted).
- **Terms §8 ("Bets are entertainment, not gambling"):** tighten to fact-based wording; remove the absolute self-serving "is not gambling" conclusion; state that the feature provides no real-world stake/prize/payout because clout has no value and cannot be cashed out.
- **Terms §2/3/4 (Eligibility — 18+):** state that access requires completing a HEAA check via a third-party partner, and prohibit circumvention (including VPNs).
- **Privacy §2/3/7/summary:** replace DOB-collection wording with the HEAA-vendor description (vendor returns only an over-18 result; Doubles does not store DOB/ID/biometric); add the vendor as a processor with location and transfer safeguard; tie the legal basis to OSA/Ofcom obligations; update retention.
- **Both — review notes/placeholders:** close legal-data.ts review notes (lines 300, 304, 309) once the vendor, region, deletion behaviour, and gambling opinion are confirmed; insert the real vendor name everywhere a placeholder appears.

---

## 5. Prioritised action checklist

### NOW (block launch / already overdue)
1. **[REQUIRED]** Integrate a HEAA vendor returning an over-18 boolean; gate access at/before sign-up. *(age)*
2. **[REQUIRED]** Complete and document the Ofcom Children's Access Assessment; do not back-date. *(age)*
3. **[REQUIRED]** Stop transmitting/storing full DOB once HEAA is live; store only result + audit metadata. *(age)*
4. **[REQUIRED]** Fix the false AES-256-GCM client-side encryption claim in legal-data.ts (line 8) and Terms (line 786). *(privacy)*
5. **[REQUIRED]** Fix the "delete account … purged" claim — correct the wording OR implement true account deletion (auth.users + users + user-keyed rows). *(privacy)*
6. **[REQUIRED — solicitor sign-off]** Instruct UK gambling counsel for a written opinion on the final clout design. *(gambling)*
7. Make purchased clout non-stakeable; enforce in `placeBet` (keep packs out of `clout_balances`). *(gambling)*
8. Lock in no-payout guarantees (no cash-out, transfer, trade, or secondary redeemable currency). *(gambling)*

### SOON (before or shortly after launch)
9. **[REQUIRED — DPO/solicitor sign-off]** Execute HEAA vendor DPA + transfer mechanism; add to ROPA; run/refresh DPIA. *(age)*
10. Set and document age-assurance retention schedule. *(age)*
11. Update App Store rating to 18+ and complete Google Play/IARC questionnaire honestly. *(age)*
12. Add spend caps + spending controls on clout/power packs. *(gambling)*
13. Re-frame gambling vocabulary in UI and store copy. *(gambling)*
14. Make the policy text edits in §4.5 (Terms §8, §2/3/4; Privacy §2/3/7). *(privacy/age/gambling)*
15. Verify the live Supabase region matches the stated EU/London (eu-west-2). *(privacy)*
16. Add anti-circumvention controls (no VPN encouragement; bind adult status to account). *(age)*

### LATER (post-launch hardening)
17. Geo-scope and geo-restrict the clout mechanic by territory. *(gambling)*
18. Maintain the internal compliance evidence pack (design + legal basis + citations). *(gambling/ops)*
19. Close all legal-data.ts review notes (lines 300, 304, 309) once the above are confirmed. *(privacy)*

### Items requiring external solicitor sign-off (do not self-certify)
- UK gambling-law opinion on the final clout design (item 6).
- Data-protection review of the HEAA vendor arrangement: DPA, international transfer mechanism, DPIA (item 9).
