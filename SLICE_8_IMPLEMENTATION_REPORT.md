# SLICE 8 — PRD-ALIGNED MOBILE IMPLEMENTATION + CROSS-SERVICE RECONCILIATION

- Date: 2026-08-18
- Scope: `Kudikit` (mobile — IMPLEMENTED). `kudikit_auth_service` and `Kudikitgateway` are **read-only reference** — no source modified; discrepancies recorded as MANUAL UPDATE REQUIRED BY PRD.
- Authority: **Kudikit Product Requirements Document V1.0** (PRD is the #1 product authority; where code contradicted it, the code was corrected — never the PRD).
- Predecessors: `SLICE_7_5_KYC_PROVIDER_BOUNDARY_REPORT.md` (COMPLETE), `SLICE_7_IMPLEMENTATION_REPORT.md`, `SLICE_7_INVESTIGATION_REPORT.md`, `SLICE_6_IMPLEMENTATION_REPORT.md`.
- Spec constraints honored: modify `Kudikit/` only; no UI redesign, no UI-flow redesign, no tier redesign; KYC provider boundary preserved (mobile never calls Dojah); GPS in scope but the provider abstraction is intact.

---

## A. Executive Summary

Slice 8 reconciles the mobile tier-upgrade flow against the PRD §2.2.4 lifecycle and the server-authoritative tier/KYC state established in Slice 7. Investigation confirmed three things:

1. **The mobile upgrade flow was a local simulation.** Profile passed the *current granted tier* into `UpgradeTierScreen` (dead-end "Current Tier" button), `_completeUpgrade` called `tierProvider.upgradeTier` (a SharedPreferences write that fabricated a grant with no server round-trip), and `UploadDocumentScreen → UpgradeSuccessScreen` fabricated "Successfully Upgraded". This violated PRD §2.2.4 (upgrade requests must flow through the system, status Submitted→Reviewing→Approved/Rejected) and the Slice 7 §7/§8 rules (server-authoritative tier, no false state).
2. **No skip enforcement on the mobile side was possible** because the flow was local-only; the PRD no-skip rule (1→2→3) was not enforced at the navigation boundary. Backend/gateway `selectTier` accept any target `> current` (only downgrades are blocked) — documented as MANUAL BACKEND/GATEWAY UPDATE REQUIRED BY PRD.
3. **The server has no Submitted→Reviewing→Approved/Rejected upgrade lifecycle.** `POST /auth/select-tier` records `pendingTier` and auto-grants when KYC is met; mobile maps real server state (`grantedTier` / `pendingTier` / typed KYC enums) to honest display states.

**Implemented (mobile only):** the profile upgrade entry now targets the single next tier above the grant (no-skip); the upgrade screen derives real per-requirement completion/rejection from server KYC state, disables on the granted tier, shows "in review" for a pending upgrade, and submits intent via the server-authoritative `AuthNotifier.selectTier` before routing into the KYC funnel. The local-only `TierNotifier.upgradeTier` simulation was removed; `UploadDocumentScreen`/`UpgradeSuccessScreen` are now unreachable (dead code, P2, files left in place).

**All acceptance criteria met.** Mobile **208 / 0 failures** (+19 Slice 8 tests; was 189 at 7.5). `flutter analyze` **0 errors / 468 issues** (unchanged baseline). Backend `49 / 0` and gateway `27 / 0` re-verified (unchanged trees, read-only). No UI redesign, no tier redesign, no GPS changes, no backend/gateway source changes, mobile still has zero Dojah credentials.

---

## B. Scope & Boundary Compliance

| Constraint | Compliance |
|---|---|
| Modify `Kudikit/` only | ✔ All changes in `Kudikit/lib` + `Kudikit/test`. |
| Never modify `kudikit_auth_service` / `Kudikitgateway` | ✔ Not modified (read-only verified at sibling paths). Discrepancies documented, never silently worked around, no invented APIs. |
| No UI redesign / no UI-flow redesign / no tier redesign | ✔ Same screens, same layout, same navigation structure; only the data feeding the existing upgrade screen and its submit action became server-authoritative. |
| KYC provider boundary preserved (mobile never calls Dojah) | ✔ Preserved (see K); Slice 7.5 boundary intact. |
| GPS in scope, provider abstraction preserved | ✔ No GPS changes; `MobileGeolocationProvider`/`BackendGeolocationProvider` untouched. |
| Prefer existing APIs; no invention | ✔ Upgrade intent goes through the existing `POST /auth/select-tier` via the existing `AuthService.selectTier`. No new endpoints invented. |
| No modifications to backend/gateway tests | ✔ None touched; suites re-run read-only. |

---

## C. Reconciliation / Implementation Plan Register

| ID | Action | State |
|---|---|---|
| MO-8.1 | Profile tier card: upgrade entry targets `granted+1` (no-skip); UNVERIFIED → KYC funnel; Mega → hidden | **DONE** |
| MO-8.2 | `UpgradeTierScreen`: server-authoritative (granted/pending/upgrade states), real requirement completion/rejection, `selectTier` submit → `KycFlowManager` | **DONE** |
| MO-8.3 | Remove local-only `TierNotifier.upgradeTier` (false-state grant simulation) | **DONE** |
| MO-8.4 | Pure helpers: `nextUpgradeTier` / `tierRequirementState` / `upgradeTierRequirementsComplete` | **DONE** |
| MO-8.5 | Slice 8 tests (no-skip, requirement states, granted-vs-pending) | **DONE** |
| BE-8.1 | No-skip enforcement in `AuthServiceImpl.selectTier` (target selection) | MANUAL BACKEND UPDATE REQUIRED BY PRD |
| BE-8.2 | Submitted→Reviewing→Approved/Rejected upgrade-request lifecycle | MANUAL BACKEND UPDATE REQUIRED BY PRD |
| BE-8.3 | Selfie persistence: encrypted S3 storage, 7-year retention (PRD Data) | MANUAL BACKEND UPDATE REQUIRED BY PRD |
| BE-8.4 | Dojah credentials env-only + rotate (Q2) | MANUAL SERVICE UPDATE REQUIRED BY PRD |
| GW-8.1 | `GET /profile` truthfulness: granted tier, Verified/Pending/Limited `kycStatus`, `pendingTier`, per-field address state | MANUAL GATEWAY UPDATE REQUIRED BY PRD |
| GW-8.2 | `/settings/tier/upgrade` no-skip (`target == current+1`) | MANUAL GATEWAY UPDATE REQUIRED BY PRD |
| D-8.1 | Onboarding-vs-upgrade distinction for backend no-skip (PRD §2.1.2 allows fresh selection of any tier) | BLOCKED — product decision |

---

## D. Mobile Changes

### D.1 `lib/model/tier/tier_requirements.dart` (NEW, MO-8.4)

Pure, testable PRD semantics (repo convention: classifier helpers shared by routing and tests):

- `nextUpgradeTier(int grantedTier)` — the **single next tier** above the server grant (`1→2→3`, PRD §2.2.4). `null` at Mega (3) or UNVERIFIED (0). Enforces no-skip at the navigation boundary: the upgrade entry can only ever offer `granted+1`.
- `tierRequirementState(String title, UserModel user)` — maps each PRD requirement (matching the `TierRequirement.title` values in `tier_model.dart`) to `incomplete / completed / rejected`, derived **only** from server KYC truth:
  - `NIN / BVN` → completed iff `isBvnVerified && isNinVerified` (Pro/Mega require BVN **and** NIN per PRD); rejected iff top-level `KycStatus.rejected`.
  - `Face verification` → `isSelfieVerified`; rejected iff server REJECTED KYC.
  - `Valid ID Card (Front & Back)` → `idDocumentStatus.verified`; rejected iff `idDocumentStatus.rejected`.
  - `Address Verification (Agent visit)` / `Utility Bill` → completed iff `addressStatus` is `verified` or `pendingAgentVisit` (PRD interim tier — the utility bill is analyzed as part of the address submission, so its completion tracks the address step); rejected iff `addressStatus.rejected`.
  - `Email/Phone Verification` → mapped from the verified flags (Basic requirements).
  - Unknown titles → `incomplete` (never guessed as done).
- `upgradeTierRequirementsComplete(UpgradeTier, UserModel)` — whole-tier gate.

No new server endpoints; no hardcoded completion; rejection is surfaced **only** where the server provides it.

### D.2 `lib/presentation/profile/profile_screen.dart` (MO-8.1)

The tier-card action button was a dead-end (`UpgradeTierScreen(tier: currentTierObj)` — passing the *current granted* tier so the screen rendered "Current Tier"). It now branches on `user.grantedTierOrZero`:

```
granted == 0  → "Start KYC"  → KycFlowManager        (UNVERIFIED — no tier to upgrade)
granted == 1  → "Upgrade Tier" → UpgradeTierScreen(Pro)    (target = granted+1, no-skip)
granted == 2  → "Upgrade Tier" → UpgradeTierScreen(Mega)
granted == 3  → (button hidden — Mega is the max tier)
```

The card's granted/pending display (Slice 7 P0-3) is unchanged; `pendingTier > grantedTier` still renders the amber "— pending" chip and is never presented as a grant.

### D.3 `lib/presentation/tier/upgrade_tier_screen.dart` (MO-8.2)

Rewritten from a local simulation to a server-authoritative screen (same layout, no redesign):

- `isCurrentTier` derives from the **server grant**: `user.grantedTierOrZero == tier.tierNumber` → disabled CTA "Current Tier".
- `requested` derives from **server intent**: `user.pendingTier == tier.tierNumber` → amber banner "Upgrade requested — in review. Complete your verification to finish." and CTA "Continue Verification" → `KycFlowManager`.
- Otherwise CTA "Continue Upgrade" → `_submitUpgrade` → `AuthNotifier.selectTier(tier.tierNumber)` (existing `POST /auth/select-tier`, which records `pendingTier` and auto-grants when requirements are already met) → `KycFlowManager` to complete the remaining PRD requirements. Server errors surface in a snackbar; no local success is ever fabricated.
- Requirement rows render real `tierRequirementState` (teal check = completed, red = server-rejected, grey = incomplete) instead of the hardcoded `isCompleted` flags.
- `UploadDocumentScreen` and `UpgradeSuccessScreen` are no longer navigated from (unreachable; P2 dead code — files left in place, see O).
- `ref.watch(currentUserProvider)` replaces the `tierProvider` dependency (local cache no longer drives the upgrade decision).

### D.4 `lib/provider/tier/tier_provider.dart` (MO-8.3)

Removed `TierNotifier.upgradeTier` — the local SharedPreferences "grant" that fabricated a tier without a server round-trip (the root of the false-state defect). `setTierFromOnboarding` remains as a **display cache** only for the onboarding selection (PRD §2.1.2: a new user may pick Basic/Pro/Mega directly); its comment now states it never grants and that upgrades are recorded via `AuthNotifier.selectTier`.

---

## E. Tier Upgrade Lifecycle — Server State Model & Mobile Mapping

PRD §2.2.4 statuses: `Submitted → Reviewing → Approved / Rejected`. The auth-service has no such state machine (BE-8.2). The mobile app therefore maps the **actual server state** onto honest display states:

| Server state (authoritative) | Mobile display |
|---|---|
| `pendingTier == target`, not granted, KYC incomplete | "Upgrade requested — in review" banner; CTA resumes the KYC funnel; profile shows "— pending". |
| `pendingTier == target`, KYC requirements met | Auto-grant path (server evaluates on select-tier); `KycFlowManager` routes to dashboard once met. |
| `grantedTier == target` | "Current Tier" — CTA disabled; profile shows the granted tier. |
| Server REJECTED KYC for a requirement (`kycStatus.rejected`, `idDocumentStatus.rejected`, `addressStatus.rejected`) | Requirement row shows the rejected state; reasons are surfaced by the existing profile badges / KycFlowManager hold states. |

A pending or locally-selected tier is never displayed as granted (Slice 7 P0-3 rule preserved; `nextUpgradeTier` uses `grantedTier`, never `pendingTier`).

---

## F. KYC Compliance & Selfie Persistence (Investigation)

- **Mobile KYC submissions** already forward the captured selfie base64 with the BVN/NIN payload to the auth-service (`POST /auth/kyc/verify-bvn|nin`), and liveness capture is a capture-only local step (Slice 7.5). Nothing more is required from the mobile app: the selfie reaches the server on the existing path.
- **PRD Data-retention gap (BE-8.3):** the PRD requires the selfie to be stored encrypted on S3 with 7-year retention. Verified (read-only) the auth-service performs identity verification via the Dojah client and persists KYC verification *results*; it does **not** persist the selfie image itself to encrypted S3. This is a backend gap (carried from Slice 7.5 Q1) — **MANUAL BACKEND UPDATE REQUIRED BY PRD**, no mobile change is applicable or permitted.

---

## G. Dojah Credentials — Q2 (Investigation Only)

- **Mobile: zero Dojah credentials** — verified again this slice; no Dojah client/config/code exists in `Kudikit` (Slice 7.5 removed it). ✔
- **Auth-service:** `application.yml` still carries sandbox Dojah `appId`/`secret` as env-var defaults (`DJ_APP_ID`/`DJ_SECRET`). Verified read-only: values are **not** committed to the repo (unset/sandbox placeholders), but the **pattern** (secrets as config defaults) is the risk — **BE-8.4 MANUAL SERVICE UPDATE REQUIRED BY PRD**: make credentials env-only (fail fast when unset) and rotate the sandbox secret. Not modified by this slice.

---

## H. Profile APIs / Gateway Reconciliation (GW-8.1)

`Kudikitgateway` exposes `GET /api/v1/profile` → `ProfileResponseDTO{ ProfileInfo, AccountInfo{ tier, tierLabel, kycStatus, … }, VerificationInfo }`. Slice 7 fixed the null-tier default (`kycLevel 0`, `kycStatus "pending"`, limits UNVERIFIED). Remaining reconciliation gaps verified read-only:

- `AccountInfo.tier` is the **granted** tier only — no `pendingTier` exposure, so the gateway cannot represent "submitted/in review" per PRD §2.2.4.
- `kycStatus` is a coarse `verified`/`pending`/`unverified` string with no `REJECTED`/`MANUAL_REVIEW`/per-requirement distinction, and address state is a single coarse `status` — insufficient for truthful per-requirement display.
- Mobile's profile/upgrade surface therefore keeps consuming the **auth-service** KYC state (`GET /auth/kyc/status` / the `user.kyc` summary) for per-requirement truth, and does **not** integrate the gateway Profile API for upgrade/KYC state (integration would reintroduce the coarse/incorrect states). `getProfile()` remains an unused service method (P2). Documented as **GW-8.1 MANUAL GATEWAY UPDATE REQUIRED BY PRD**; integration should be revisited after the gateway is truthful.

---

## I. Backend Findings / MANUAL BACKEND UPDATE REQUIRED BY PRD

### I.1 BE-8.1 — No-skip not enforced at target selection

Verified (read-only, `kudikit_auth_service`): `AuthServiceImpl.selectTier` blocks only **downgrade** (`Cannot downgrade below your current tier`) and then sets `pendingTier`; `TierProgressionService` grants the highest fully-met tier ≤ pendingTier (cumulative, never above it — so the **grant** path is no-skip). What remains permissive is **target selection**: a user may select Mega before Basic/Pro are granted. Under the strict PRD reading of "users cannot skip tiers" (§2.2.4), selecting a higher target before the immediately-previous tier is granted is a skip.

**Status: MANUAL BACKEND UPDATE REQUIRED BY PRD** — add a select-level guard (require `target <= granted+1` for existing users, while preserving fresh onboarding selection per PRD §2.1.2 — see D-8.1). Not implemented here, not reinterpreted.

### I.2 BE-8.2 — Upgrade lifecycle state machine absent

No Submitted→Reviewing→Approved/Rejected request model, field, or endpoint exists. `pendingTier` is a coarse intent field; there is no per-request approval/rejection signal beyond the derived KYC enums and rejection reasons. Mobile maps real state (Section E) rather than inventing status. **Status: MANUAL BACKEND UPDATE REQUIRED BY PRD.**

### I.3 BE-8.3 / BE-8.4

Selfie S3 persistence (F) and env-only Dojah credentials (G). **Status: MANUAL BACKEND/SERVICE UPDATE REQUIRED BY PRD.**

### I.4 Backend suite

`mvn test -DskipITs` → **49 tests, 0 failures** (re-verified read-only; unchanged trees).

---

## J. Gateway Findings / MANUAL GATEWAY UPDATE REQUIRED BY PRD

### J.1 GW-8.1 — Profile API truthfulness/coverage (see H)

Granted-tier truth was fixed in Slice 7; `pendingTier` and per-requirement KYC states are still missing. **MANUAL GATEWAY UPDATE REQUIRED BY PRD.**

### J.2 GW-8.2 — `/settings/tier/upgrade` no-skip

`SettingsController.requestTierUpgrade` proxies tier selection and validates only `target > current` (upgrade direction) — it does **not** enforce `target == current + 1`, so a skip (Basic → Mega) is accepted. **MANUAL GATEWAY UPDATE REQUIRED BY PRD** (align with BE-8.1 once the backend guard exists). Not modified.

### J.3 Gateway suite

`mvn test -DskipITs` → **27 tests, 0 failures** (re-verified read-only; unchanged trees).

---

## K. KYC Provider Boundary Preservation

Re-verified this slice: `Kudikit` has no direct provider integration. Identity verification is submitted to the **auth-service** only (`verifyBvn`/`verifyNin` with the captured selfie; `selectTier`; `refreshKycStatus`). Liveness capture is capture-only (Slice 7.5). No new network path was added by Slice 8 — the upgrade flow reuses the existing `selectTier` service method. Boundary intact.

---

## L. Test Results

| Suite | Slice 7.5 | After | New tests |
|---|---|---|---|
| Mobile `flutter test` | 189 / 0 | **208 / 0** | `test/tier_requirements_test.dart` (19): no-skip `nextUpgradeTier` (1→2, 2→3, Mega/UNVERIFIED → null, pending never drives the entry); `tierRequirementState` mapping (BVN **and** NIN, ID verified/manual-review/rejected, address verified + PRD interim `pendingAgentVisit`, utility-bill tracking, email/phone, unknown-title fallback); `upgradeTierRequirementsComplete` whole-tier gate; granted-vs-pending never-presented-as-granted. |
| Backend `mvn test -DskipITs` | 49 / 0 | **49 / 0** (re-verified, read-only) | — |
| Gateway `mvn test -DskipITs` | 27 / 0 | **27 / 0** (re-verified, read-only) | — |
| `flutter analyze` | 0 errors / 468 | **0 errors / 468** (unchanged) | — |

**Primary acceptance scenario (verified at the model/classifier level by tests + code inspection):**

```
Basic (grant 1) user taps Upgrade Tier
  ├─ entry targets Pro (2) only — no skip to Mega             ✔ MO-8.1 / nextUpgradeTier
  ├─ requirement rows = real server KYC state (BVN&&NIN,
  │    selfie, ID doc), rejected rows surfaced only on server REJECTED  ✔ MO-8.2 / tierRequirementState
  ├─ pendingTier == 2 → "in review / Continue Verification"   ✔ no false grant
  ├─ grantedTier == 2 → disabled "Current Tier"               ✔ server-authoritative
  └─ "Continue Upgrade" → POST /auth/select-tier {tier:PRO} → KycFlowManager
        (server records pendingTier; auto-grants when met)    ✔ no local simulation
```

---

## M. Regression Verification

| # | Guard | Status |
|---|---|---|
| 1 | Slice 5 verification APIs intact | ✔ untouched |
| 2 | Slice 6 tier-aware KYC routing intact | ✔ `KycFlowManager` untouched; existing routing tests pass |
| 3 | Slice 6 GPS provider abstraction intact | ✔ no changes; GPS tests pass |
| 4 | Slice 6/7 boot/resume KYC reconciliation intact | ✔ `auth_provider` untouched |
| 5 | Slice 7 P0-3 granted-vs-pending display intact | ✔ profile/home unchanged; slice7 tests pass |
| 6 | Slice 7.5 KYC provider boundary intact | ✔ no direct-provider path (K) |
| 7 | Onboarding tier selection intact | ✔ `choose_tribe.dart` untouched (PRD §2.1.2 direct selection preserved) |
| 8 | No local tier cache can override the server grant in the upgrade path | ✔ upgrade screen reads `currentUserProvider`; `tierProvider.upgradeTier` removed |
| 9 | No UI redesign / flow redesign introduced | ✔ existing screens/layouts only; data + submit behavior corrected |
| 10 | No backend/gateway source modified | ✔ read-only re-verification |

---

## N. PRD Reconciliation

| PRD requirement | Resolution |
|---|---|
| **Upgrade Tier option in profile** (§2.2.4) | ✔ Entry targets the single next tier (granted+1); hidden at Mega; UNVERIFIED → KYC. |
| **Tier 1→2 identity document; 2→3 address + agent visit** | ✔ Per-requirement completion derived from real server KYC state (BVN/NIN/selfie/ID doc/address/utility). |
| **Status Submitted→Reviewing→Approved/Rejected** | ✔ Mobile shows real server state (granted / "in review" pending / rejected per requirement); full state machine = **BE-8.2 MANUAL BACKEND UPDATE REQUIRED BY PRD**. |
| **No tier skipping (1→2→3)** | ✔ Enforced at the mobile navigation boundary (`nextUpgradeTier` = granted+1). Server/gateway target selection = **BE-8.1 / GW-8.2 MANUAL UPDATE REQUIRED BY PRD**. |
| **Granted vs pending semantics** | ✔ Upgrade never presents pending as granted; "Current Tier" only on server grant. |
| **Eligibility / status dashboard** | ✔ Honest "in review" banner + profile pending chip; rejection shown per server data. |
| **KYC status / tier truth (Profile)** | ✔ Auth-service KYC state is the display authority; gateway Profile kept out until truthful (**GW-8.1**). |
| **Selfie stored encrypted, 7-yr retention** | **BE-8.3 MANUAL BACKEND UPDATE REQUIRED BY PRD** (mobile already forwards the selfie on the existing path). |
| **No direct provider access / no creds in mobile** | ✔ Preserved; Q2 = **BE-8.4 MANUAL SERVICE UPDATE** (env-only + rotate). |

---

## O. Remaining P1/P2 Work

| # | Item | Status / owner |
|---|---|---|
| O1 | **BE-8.2 upgrade lifecycle state machine** (Submitted/Reviewing/Approved/Rejected + per-request status endpoint) | Backend / next slice |
| O2 | **BE-8.1 + GW-8.2 no-skip at target selection** (needs D-8.1 product decision on onboarding-vs-upgrade) | Backend + gateway |
| O3 | **BE-8.3 selfie S3 persistence (7-yr encrypted)** | Backend |
| O4 | **BE-8.4 env-only Dojah creds + rotate** | Backend (ops) |
| O5 | **GW-8.1 truthful profile (`pendingTier`, per-requirement status)** then integrate `getProfile()` | Gateway + mobile follow-up |
| O6 | P2 dead code: `upload_document_screen.dart`, `upgrade_success_screen.dart`, `tier_management_screen.dart`, `tier_selection_screen.dart`, `getProfile()` service method, `UploadDocument` model, gateway Shufti-era DTOs | cleanup slice |
| O7 | **GW-4 `checkTransactionLimits` stub** (carried from Slice 7) | Gateway / next slice |

---

## P. Blocked Decisions

| ID | Decision needed | Blocker |
|---|---|---|
| D-8.1 | Onboarding-vs-upgrade distinction for backend no-skip: PRD §2.1.2 lets a new user select Basic/Pro/Mega directly, while §2.2.4 forbids skipping on upgrade. The backend guard must allow fresh multi-tier selection but forbid non-sequential **upgrades** (e.g. via a `isOnboarding`/first-selection flag). | Product confirmation of the exact distinction before implementing BE-8.1/GW-8.2. |

---

## Q. Evidence / Verification Methodology

- PRD: `Kudikit Product Requirements Document V1.0` — §2.1.2 tier selection, §2.1.4 Tier-1 KYC flow, §2.2.4 tier upgrade request, profile requirements, Data-retention (selfie/S3), and §7/§8 implementation principles.
- Mobile: `flutter test` (208) and `flutter analyze` (0 errors / 468 issues) executed in `Kudikit/`.
- Backend/gateway: `mvn test -DskipITs` executed read-only at the sibling repos (`kudikit_auth_service` 49, `Kudikitgateway` 27) — no source changes.
- Read-only code verification: `AuthServiceImpl.selectTier`/`AuthController`, `TierProgressionService`, `SettingsController.requestTierUpgrade`, `ProfileController`/`ProfileResponseDTO`, `application.yml` (Dojah env-var defaults), mobile `AuthService.selectTier`/`getProfile`, `UpgradeTierScreen`, `profile_screen`, `tier_provider`, `tier_model`.
- Slice 8 diff reviewed: 5 mobile files (4 modified + 1 new helper + 1 new test file).

---

## S. Follow-up — Mobile consumption of the backend MEGA review lifecycle (BE-8.1/BE-8.2)

After this report, the auth-service implemented BE-8.1/BE-8.2 manually (user's commit
`ed6220c` on branch `falodun_ebenezer_dev`, NOT pushed): MEGA (tier 3) is human-gated —
`selectTier(MEGA)` creates a `TierUpgradeRequest` (SUBMITTED); KYC stays at tier 2 until an
admin approves; SUBMITTED→REVIEWING→APPROVED/REJECTED; manual review only on tier 3;
Basic/Pro remain auto-granted; `GET /auth/kyc/tier-upgrade/status` + admin
`/tier-upgrades/pending|approve|reject` added; `KycStatusSummary` now carries
`tierUpgradeStatus` + `tierUpgradeReviewNotes` (auth `UserResponse.user.kyc`).

The mobile equivalents were implemented and verified here:

- **M1 — model:** `KycStatusSummary` now parses/serializes `tierUpgradeStatus` +
  `tierUpgradeReviewNotes` (`lib/model/user/kyc_status.dart`); new `TierUpgradeStatus` enum
  (submitted/reviewing/approved/rejected, null-safe) and `TierUpgradeStatusInfo` map the
  `GET /auth/kyc/tier-upgrade/status` payload (`targetTier`/`status`/`reviewNotes`/
  `submittedAt`/`decidedAt`).
- **M2 — `UserModel`:** carries `tierUpgradeStatus` + `tierUpgradeReviewNotes` through
  `copyWith`/`copyWithKyc`/`toJson`/`fromJson` and folds them from the server KYC summary
  in `fromAuthResponse` (server wins; cache preserved otherwise).
- **M3 — provider/service:** `AuthService.getTierUpgradeStatus()` (GET
  `/auth/kyc/tier-upgrade/status`) and best-effort `AuthNotifier.refreshTierUpgradeStatus()`
  wired into authenticated boot reconciliation alongside `refreshKycStatus()`.
- **UI (PRD-compliant):** staged labels are NEVER surfaced. The upgrade screen keeps the
  PRD "Pending" display — banner now reads "Upgrade request pending — complete your
  verification to finish."; the profile chip retains "— pending".
- **Verification:** `flutter test` 216/0 (+8 new tests across `kyc_status_test`,
  `auth_services_test`, `slice7_p0_tier_semantics_test`, `auth_provider_test`), `flutter
  analyze` 0 errors / 468 issues (baseline unchanged).

**Recommended backend follow-up (GET /auth/kyc/status):** the mobile already derives the
lifecycle from `user.kyc` at auth and from the dedicated tier-upgrade endpoint on boot. For
fresh reads after admin decisions without a re-login, populate the two lifecycle fields on
`GET /auth/kyc/status` too: add `@Transient TierUpgradeStatus tierUpgradeStatus` +
`@Transient String tierUpgradeReviewNotes` to `KycVerification` and fill them from the
latest `TierUpgradeRequest` in `KycController.status`. This is backward-compatible —
`KycStatusSummary.fromJson` already reads both keys and tolerates their absence.

---

## R. Final Decision / Next Slice Recommendation

**SLICE 8: COMPLETE.**

All mobile-scope targets are implemented, regression-tested, and PRD-reconciled. The upgrade flow is now server-authoritative, no-skip at the navigation boundary, and incapable of fabricating a grant. All backend/gateway gaps are documented as MANUAL UPDATE REQUIRED BY PRD and remain untouched per the boundary rules.

**Recommended next slices (priority order):**
1. **Tier-upgrade lifecycle (BE-8.2)** — backend implemented by the user (commit `ed6220c`); mobile consumption done in §S. Remaining: the advised `GET /auth/kyc/status` `@Transient` fields (see §S) and pushing `ed6220c`.
2. **No-skip backend/gateway guard (BE-8.1/GW-8.2)** — after product resolves D-8.1 (onboarding-vs-upgrade distinction).
3. **Selfie S3 persistence (BE-8.3)** and **env-only Dojah creds (BE-8.4)** — closes the two carried PRD compliance gaps.
4. **Truthful gateway Profile (GW-8.1)** + mobile `getProfile()` integration.
5. **P2 dead-code cleanup (O6)** and **GW-4 transaction-limit enforcement (O7)**.
