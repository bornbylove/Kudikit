# SLICE 7 — P0 CODEBASE HARDENING: AUTHORIZATION, LOGIN GATING & TIER TRUTH

- Date: 2026-08-18
- Scope: `Kudikit` (mobile), `Kudikitgateway`, `kudikit_auth_service` (backend — audit only)
- Authority: **Kudikit Product Requirements Document V1.0** (PRD is the #1 product authority; where code contradicted it, the code was corrected — never the PRD).
- Predecessor: `SLICE_7_INVESTIGATION_REPORT.md` (read-only), `SLICE_6_IMPLEMENTATION_REPORT.md`.

---

## A. Executive Summary

The Slice 7 investigation proved the observed symptom — *"a user can log in, reach the dashboard, and appear to be Tier 1 without completing liveness"* — is **not** a backend Basic-tier grant (that path is fail-closed). It is the combination of three independent P0 defects:

1. **Mobile login bypass (P0-2):** `login_page.dart` navigated straight to `BottomNavBar` after login, skipping the Slice 6 KYC gate.
2. **Gateway null-tier → BASIC (P0-1):** `UserSyncService.kycLevelFor(null)` returned `1` and `User.kycLevel` defaulted to `1`, so an unverified user received Basic limits, a Basic badge, and a profile that could report `tier: 1 / kycStatus: "verified"`.
3. **Mobile tier display (P0-3):** `UserModel._tierStringToInt(null) → 1`, and display surfaces conflated pending/selected/local-provider tiers with the granted tier.

This slice implements the P0 hardening pass:

- **P0-1** — Gateway now represents an ungranted tier as `UNVERIFIED` (kycLevel `0`), never Basic; the Profile API is truthful; null-guards added to every kycLevel consumer.
- **P0-2** — Login routes through the existing `KycFlowManager` gate (no second KYC router, no duplicate classification). A user with no liveness is funnelled, never dashboarded.
- **P0-3** — Mobile distinguishes **granted** (server `UserModel.grantedTier`) from **pending** (`pendingTier`) and **local intent** (`selectedTier`/provider). Null granted tier displays as `UNVERIFIED`, never "Tier 1".

**All acceptance criteria met.** Test counts: mobile **211 / 0 failures** (+15), gateway **27 / 0** (+14), backend **22 / 0** (unchanged). `flutter analyze` **0 errors** (470 info/warnings — unchanged). No UI redesign, no GPS changes, no backend semantic changes.

---

## B. Changes Made

| Area | File | Change |
|---|---|---|
| Gateway P0-1 | `security/UserSyncService.java` | `kycLevelFor(null)` → `0` (UNVERIFIED); `refresh()` now syncs kycLevel **including** null-tier claims (corrects stale rows defaulted to 1); added `TIER_UNVERIFIED_KYC_LEVEL`. |
| Gateway P0-1 | `entity/User.java` | `kycLevel` field default `1` → `0` (fail-safe UNVERIFIED for unsynced/ungranted read-models). |
| Gateway P0-1 | `service/impl/ProfileServiceImpl.java` | `getTierLabel`/`getTierIcon` null-guards (unboxing switches would NPE on null); `getMissingFields` counts `null` tier as missing `kyc_verification`. |
| Gateway P0-1 | `service/impl/DashboardServiceImpl.java` | `getTierLabel` null-guard; "Request Card" quick-action guarded (`kycLevel >= 2` only); upgrade message truthful for unverified ("Complete KYC verification…" instead of "Upgrade to Basic Tribe"). |
| Gateway P0-1 | `service/impl/AgentServiceImpl.java` | Tier-2 agent check null-guarded (ungranted denied). |
| Gateway P0-1 | `entity/UserProfile.java` | Completeness-score kycLevel check null-guarded. |
| Gateway P0-1 | `util/TierLimits.java` | **No change needed** — `forTier(null|0)` already → `UNVERIFIED` (₦10k/₦10k); 1/2/3 → Tier1/2/3 limits preserved. Now actually reachable. |
| Mobile P0-2 | `lib/presentation/login/login_page.dart` | Post-login navigation: `BottomNavBar` → `KycFlowManager` (reuses the Slice 6 authoritative, tier-aware gate; device-verification 202 path unchanged). |
| Mobile P0-3 | `lib/model/user/user_model.dart` | New `int? grantedTier` (server-authoritative; null = UNVERIFIED) + `grantedTierOrZero` / `hasGrantedTier` helpers; parsed from the auth-service `tier` field in `fromAuthResponse`/`fromJson`, serialized in `toJson`, supported in `copyWith`. `pendingTier` and `selectedTier` are untouched and remain routing intent only. |
| Mobile P0-3 | `lib/presentation/homescreen/home_screen.dart` | Header tier pill derives from `user.grantedTierOrZero`; shows `UNVERIFIED` when no grant (was `tierProvider.currentTier`). |
| Mobile P0-3 | `lib/presentation/profile/profile_screen.dart` | Header pill + tier card derive from the granted tier (was `pendingTier → selectedTier → provider`); "pending" chip now means `pendingTier > grantedTier` (was `> selectedTier`); unverified tier card labelled `UNVERIFIED` (no fabricated "(Tier 1)"). |

No backend (`kudikit_auth_service`) source changes were made. No `TierLimits` limit values were invented or changed.

---

## C. Mobile Changes

### C.1 Login gate (P0-2)

`login_page.dart` `_handleLogin`:

```
login() ok ──> requiresDeviceVerification ? SignInVerifyEmailScreen (unchanged)
                                          └──> KycFlowManager (was: BottomNavBar)
```

`KycFlowManager` was not modified — it is the single Slice 6 authoritative router (server-authoritative `effectiveTier`, per-tier PRD completion, async hold states `MANUAL_REVIEW/REJECTED/EXPIRED`, `PENDING_AGENT_VISIT` interim). The login path now uses exactly the same gate as splash/boot. No second KYC router was created; no classification logic duplicated.

### C.2 Granted vs pending/null tier (P0-3)

The mobile tier model now has three distinct notions:

```
grantedTier   — server-authoritative grant (null = UNVERIFIED)  ← DISPLAY uses this
pendingTier   — tier being worked toward (server `pendingTier`)  ← "pending" indicator
selectedTier  — local onboarding intent (routing fallback)       ← never displayed as granted
tierProvider  — local cache (routing fallback only)              ← never displayed as granted
```

- `UserModel.grantedTier` is parsed **only** from the server `tier` field; it is never defaulted to 1.
- Home header and Profile header/tier-card render from `grantedTier`; a null grant renders `UNVERIFIED`.
- The Profile card's `pending` chip is shown only when `pendingTier > grantedTier` — pending is preserved and represented, never presented as a grant.
- Routing intent (`KycFlowManager.effectiveTier` = `pendingTier → selectedTier → provider`) is unchanged and kept separate from authorization state.

---

## D. Gateway Changes

### D.1 Semantic model

| `JWT tier` claim | `User.kycLevel` | `TierLimits.forTier` | Profile `account.tier` / `kycStatus` |
|---|---|---|---|
| `null` (ungranted) | **0 — UNVERIFIED** (was 1) | UNVERIFIED ₦10k/₦10k | `0` / `"pending"` (was `1` / `"verified"`) |
| `BASIC` | 1 | TIER_1 ₦50k/₦50k | `1` / `"verified"` |
| `PRO` | 2 | TIER_2 ₦500k/₦200k | `2` / `"verified"` |
| `MEGA` | 3 | TIER_3 ₦3M/₦1M | `3` / `"verified"`, address `"verified"` |

`UserSyncService.kycLevelFor` previously returned `TIER_BASIC_KYC_LEVEL (1)` for a null claim and only synced kycLevel when the claim was non-null — so every unverified user was both provisioned **and** kept at Basic. Now `null → 0`, and `refresh()` writes the resolved value on every request (correcting legacy rows defaulted to 1). `User.kycLevel`'s Java default is `0`.

### D.2 Profile API reconciliation

`GET /api/v1/profile` (`ProfileServiceImpl.getUserProfile`) is now truthful for ungranted users: `account.tier = 0`, `tierLabel = "Not Verified"`, `tierIcon = "none"`, `kycStatus = "pending"`, `verification.{bvn,nin}.verified = false`, `verification.address.status = "pending"`, and `missingFields` includes `kyc_verification`. Granted tiers report exactly as before. `POST /profile/update-profile`, `GET /profile/completeness`, `GET /profile/referral` unchanged.

### D.3 Transaction-limit / authorization audit

- `EntryServiceImpl.checkTransactionLimits` remains an **empty stub** and is **not wired into any real transaction path** (it is a plain class, no Spring component, no callers). It neither grants nor denies — this is the pre-existing **GW-4 gap**, left intact and documented (H).
- With P0-1, **no path defaults a null tier to Basic**: `TierLimits.forTier(0|null) → UNVERIFIED`; `DashboardServiceImpl.buildWalletLimits` therefore returns UNVERIFIED limits for ungranted users. Transaction-facing surfaces no longer show Basic limits for an unverified user.
- In practice an ungranted user cannot transact via the wallet flow anyway (no wallet is provisioned below tier-1; `ensureWallet` fires only on a tier-1 upgrade), and agent onboarding now requires Tier 2 with a null-safe check. The remaining enforcement gap (limits not applied server-side at transaction time) is explicitly **not** marked complete — see H.

---

## E. Backend Findings / Manual Updates Required

### E.1 No-skip rule — MANUAL BACKEND UPDATE REQUIRED BY PRD (tracked, not silently changed)

Verified current behavior in `kudikit_auth_service`:

- `AuthServiceImpl.selectTier` blocks only **downgrades**, then records `pendingTier` (intent) immediately.
- `TierProgressionService.highestMetTier` grants the **highest fully-met tier ≤ pendingTier**, cumulative (`BASIC` floor → `PRO` → `MEGA`), never above the selected tier, never downgrades.

The **grant path fully enforces 1→2→3** (a user cannot be granted Pro without Basic, nor Mega without Pro). What remains permissive is **target selection**: a user may *select* Mega as a target before completing Basic/Pro. Under the PRD's strict reading of "users cannot skip tiers", selecting a higher target before the lower tier is granted is a skip.

**Status: MANUAL BACKEND UPDATE REQUIRED BY PRD** — a `selectTier`-level guard (e.g. require the immediately-previous tier to be granted before accepting a higher `pendingTier`, or a documented product decision that target selection may be free while grant remains cumulative). Not implemented in this slice, not reinterpreted.

### E.2 Backend test suite

`kudikit_auth_service` — **22 tests, 0 failures** (unchanged). No backend code modified.

---

## F. Test Results

| Suite | Baseline | After | New tests |
|---|---|---|---|
| Mobile `flutter test` | 196 / 0 failures | **211 / 0 failures** | `test/slice7_p0_tier_semantics_test.dart` (15): null granted tier → UNVERIFIED not Tier 1; BASIC/PRO/MEGA → 1/2/3; `pendingTier` ≠ `grantedTier`; `selectedTier` not treated as granted; JSON round-trip; `copyWith`; grant parsed independently of KYC booleans; no-liveness → funnel (never complete); granted Basic (NIN-only) / Pro / Mega → dashboard (Slice 6 gates retained); `effectiveTier` keeps routing intent separate from grant. |
| Gateway `mvn test -DskipITs` | 13 / 0 | **27 / 0** | `util/TierLimitsTest` (5): null/0 → UNVERIFIED, 1/2/3 → Tier1/2/3 limits. `service/impl/ProfileServiceImplTest` (6): unverified reports tier 0 / "Not Verified" / "pending" / BVN+NIN false; null kycLevel also unverified; Basic/Pro/Mega report 1/2/3 "verified"; Mega address verified; missing-field includes `kyc_verification`. `security/UserSyncServiceTest` (+3): null tier provisioned as 0; null tier refresh corrects stale Basic→0; BASIC refresh promotes 0→1. |
| Backend `mvn test -DskipITs` | 22 / 0 | **22 / 0** | — (unchanged) |
| `flutter analyze` | 0 errors / 470 issues | **0 errors / 470 issues** | — |

**Primary acceptance scenario** (verified at the routing/model level by tests, plus code inspection):

```
OTP registration/login → no liveness → login → KycFlowManager
  ├─ classify → continueFunnel (NOT complete)          ✔ never lands on dashboard
  ├─ gateway kycLevel = 0 → UNVERIFIED limits (₦10k)   ✔ never Basic limits
  ├─ gateway Profile: tier 0 / kycStatus pending       ✔ never "Tier 1"/"Verified"
  └─ mobile: grantedTier null → header shows UNVERIFIED ✔ never granted Tier 1
```

---

## G. Regression Verification

| # | Guard | Status |
|---|---|---|
| 1 | Slice 5 verification APIs intact | ✔ unchanged |
| 2 | Slice 6 tier-aware KYC routing intact | ✔ `KycFlowManager` untouched; existing 20 routing tests pass |
| 3 | Slice 6 GPS provider abstraction intact | ✔ no changes; 6 GPS tests pass |
| 4 | Slice 6 boot/resume KYC reconciliation intact | ✔ `auth_provider` untouched; boot-reconcile tests pass |
| 5 | Profile API integration intact | ✔ `getProfile()` consumer unchanged; gateway now truthful |
| 6 | `PENDING_AGENT_VISIT` interim behavior intact | ✔ classify tests pass |
| 7 | `MANUAL_REVIEW` intact | ✔ hold-state tests pass |
| 8 | `REJECTED` reconciliation intact | ✔ hold-state/reason tests pass |
| 9 | No UI redesign introduced | ✔ only data/text corrections in existing widgets |
| 10 | No GPS functionality removed | ✔ |
| 11 | No local tier state can override server-authoritative granted tier | ✔ display derives from `UserModel.grantedTier`; home/profile no longer read `tierProvider` for the tier badge |

---

## H. Remaining P1/P2 Work

| # | Item | Status / owner |
|---|---|---|
| H1 | **GW-4 `checkTransactionLimits` stub** — entry-point limit enforcement is unimplemented and uncalled. Not marked complete. | Gateway / next slice |
| H2 | **No-skip select-level guard** — see E.1 (MANUAL BACKEND UPDATE REQUIRED BY PRD). | Backend |
| H3 | **Submitted → Reviewing → Approved → Rejected upgrade lifecycle** — not implemented (out of scope). | Backend/mobile |
| H4 | **`upgrade_tier_screen.dart` local-only tier simulation** (`tierProvider.upgradeTier`) — local upgrade still writes SharedPreferences without a server round-trip; part of the broader upgrade lifecycle (out of scope). | Mobile, with H3 |
| H5 | **PIN → CBA account → NumBan → wallet → activation chain** — no bank integration exists (BLOCKED on partnerships, Slice 6 C.5). | Backend/product |
| H6 | Notification infrastructure, dashboard/profile redesign, new bank integrations — out of scope per slice spec. | — |

---

## I. PRD Reconciliation

| PRD requirement | Resolution |
|---|---|
| **UNVERIFIED is not Basic** | Gateway now maps null/0 → UNVERIFIED (limits, badge, profile) — no inferred grant from `pendingTier`, `selectedTier`, kycLevel defaults, registration existence, or OTP completion. |
| **Login must pass the PRD gate** | Login routes through `KycFlowManager`; the routing decision uses granted/pending tier, KYC state, ID-document state, address state (authoritative). |
| **Granted vs pending/null display** | `grantedTier` is the only display authority; pending is preserved and shown as "pending"; null shows `UNVERIFIED`. |
| **Tier 1 = liveness + (BVN OR NIN)** | Retained (existing tests) — NIN-only Basic still completes. |
| **Tier 2 = Basic + BVN AND NIN + valid ID** | Retained. |
| **Tier 3 = Pro + address** | Retained; `PENDING_AGENT_VISIT` interim → dashboard. |
| **No tier skipping** | Grant path cumulative and no-skip (verified); target *selection* permissive → **E.1 MANUAL BACKEND UPDATE REQUIRED BY PRD**. |
| **Profile truthful** | Gateway Profile reflects real server state (granted tier only). |
| **GPS in scope** | Slice 6 provider abstraction intact (no change). |

---

## J. Final Decision / Next Slice Recommendation

**Slice 7 P0 hardening: COMPLETE.**

All P0 targets are implemented, regression-tested, and verified against the original observed scenario. The decision gate from the investigation (`CONDITIONAL GO`) is now cleared: the gateway is truthful about null tiers, login cannot bypass the KYC gate, and the mobile app never displays a null/pending/selected tier as granted.

**Recommended next slice (P1):**
1. **Backend no-skip select guard** (E.1) — resolve the target-selection vs grant semantics with product, then implement (blocked on a product decision or direct PRD-mandated guard).
2. **Tier-upgrade lifecycle** (H3/H4) — `Submitted → Reviewing → Approved → Rejected` + wire the upgrade screen to the server (`SettingsServiceImpl.requestTierUpgrade` / `selectTier`) instead of the local simulation.
3. **GW-4 transaction-limit enforcement** (H1) — implement `checkTransactionLimits` against `TierLimits` + kudikitpayment.
4. **Wallet/CBA activation** (H5) — dedicated slice with explicit bank-partnership decisions.
