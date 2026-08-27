# SLICE 7 — PRD-ALIGNED TIER GRANT, LOGIN GATING & TIER UPGRADE INVESTIGATION

**Type:** Read-only investigation / reconciliation. **No code was modified.**
**Scope:** Kudikit Mobile (Flutter), kudikit_auth_service, KudikitGateway, KudikitPayment (where relevant), PRD `Kudikit_Product Requirements Document-V.1.pdf` (extracted to `/tmp/kudikit_prd.txt`).
**Date:** 2026-08-18
**Primary question:** *"A user can apparently log in, reach the dashboard, and appear to have Tier 1 / Basic status without completing liveness/selfie verification."* — establish exactly what happens and whether the appearance has any real authorization/financial consequence.

> **PRD authority rule applied throughout:** when implementation conflicts with the PRD, the PRD wins. The implementation is NOT normalized to excuse current behavior. Contradictions are recorded with the exact change required, and those that cannot be fixed by code changes in this slice are flagged **MANUAL BACKEND UPDATE REQUIRED**.

---

## A. EXECUTIVE SUMMARY

**The observed behavior is reproducible, and it is a combination of options F + B + A from the investigation brief — NOT a backend grant bypass (C/D are false).**

| Hypothesized cause | Verdict |
|---|---|
| A. Client-side display/fallback makes user APPEAR Tier 1 | **TRUE** — mobile `_tierStringToInt(null)→1`, `selectedTier` default, profile/home render "Tier 1" |
| B. Gateway classifies null/unverified tier as Basic | **TRUE** — `UserSyncService.kycLevelFor(null)→1`, `User.kycLevel` default `1` → **BASIC limits** |
| C. Backend grants BASIC before liveness | **FALSE** — `TierProgressionService` requires `livenessVerified && (bvn||nin)`; `livenessVerified` only via Dojah success |
| D. JWT carries BASIC claim before liveness | **FALSE** — `JwtTokenProvider` mints tier claim from granted `user.getTier()` (null until granted) |
| E. Gateway grants Tier-1 transaction limits to unverified user | **TRUE** — BASIC limits ₦50k/₦50k are displayed/applied for a null-claim user (see §G) |
| F. Mobile login bypasses KYC routing → dashboard before KYC | **TRUE** — `login_page.dart:172-176` pushes `BottomNavBar` directly |
| G. Multiple simultaneously true | **TRUE** — F (dashboard entry), B+E (limits), A (display) |

**Bottom line:** the backend's *grant* is safe. No code path grants BASIC to a user who has never completed liveness. But **two P0 defects** make the appearance real:

1. **Dashboard access before KYC** (mobile, pre-existing, not a Slice 6 regression): any successful passcode login lands on `BottomNavBar` with no KYC/liveness/registration-complete gate (`login_page.dart:172-176`).
2. **Null granted tier ⇒ BASIC at the authorization boundary** (gateway): an OTP-only registrant (server `tier=null`) is mapped to `kycLevel=1` and receives **Tier-1 limits (₦50,000 daily / ₦50,000 single)** in dashboard/profile, and profile reports `tier:1, kycStatus:"verified"`. This is a **security/business-rule defect, not a display bug** (§G).

Secondary P1 findings: tier upgrade is a **local-only simulation** on mobile (`upgrade_tier_screen.dart:184` never calls the backend); the PRD's **Submitted → Reviewing → Approved/Rejected** upgrade lifecycle does not exist; **no-skip (1→2→3)** is not enforced at selection; the **PIN → CBA → NumBan → wallet** activation lifecycle is not implemented anywhere in the primary flow; and the **gateway transaction-limit enforcement is an empty stub** (`EntryServiceImpl.checkTransactionLimits`).

**Decision gate: CONDITIONAL GO** — the next implementation slice is authorized **only for the P0 set** (§K.1), after which this investigation must be re-run end-to-end. See §Decision Gate.

---

## B. PRD TIER / KYC REQUIREMENTS (extracted)

From `/tmp/kudikit_prd.txt` (page-line references):

### §2.1.2 — Account Tier Selection & KYC Initiation
- User selects a tier (Basic/Pro/Mega) and proceeds to that tier's KYC.
- **"Cannot auto-select tier for user (must be explicit choice)."**
- Selecting a tier is **selection**, not grant. Grant happens when KYC for that tier is met (the PRD's Tier-1 flow ends with an "Acct Created! … Welcome … to Kudikit Basic" notification, i.e., Basic is achieved after KYC + activation).
- KYC requirements per tier are displayed before choosing.

### §2.1.4 — Tier 1 (Basic) KYC Flow (sequence)
1. **Selfie capture** — face detected, not blurry, eyes open. *"Liveness detection: Optional blink/head movement check."*
2. **ID selection** — radio: BVN or NIN.
3. **BVN/NIN verification using the selfie image** — failure cases: "Invalid BVN"→Retry; "Image doesn't match"→Retake selfie; "Service unavailable"→Try later or use NIN.
4. **Transaction PIN** (4-digit) creation.
5. **Account Creation & Activation** — call Bank CBA API → webhook → **NumBan** → map user → **create wallet**.
6. **Success screen** → **navigate to dashboard**.
7. **Pending path** (CBA delayed): *"Creating your account…"* → **"Allow limited dashboard access"** → push notification when ready.
- Tier 1 = **"activate my account with ₦50,000 daily limits"**.
- Notification copy: *"Acct Created! Welcome Adebayo to Kudikit Basic. Acct No … Daily limit: ₦50,000."*

**Eligibility for the normal dashboard experience:** only after the full activation chain (selfie/BVN-NIN → PIN → CBA → NumBan → wallet). Before that, only **limited dashboard access** is permitted (and only while CBA is pending — not before KYC).

### §2.1.5 — Tier 2 (Pro)
- **All Tier-1 requirements plus BVN AND NIN plus a valid ID document (front/back).**
- Document review lifecycle exists (§2.2.4): Submitted → Reviewing → Approved/Rejected; expired documents rejected; auto-KYC checks on admin approval; **limited functionality during review** ("Status: In review", "Expected decision: Within 24 hours").
- **Returning User / Resume** (§2.1.5 epic): detect incomplete registration via the **`registration_complete` flag** → Resume screen: *"Continue Your Registration", "Step 4 of 7: Verify NIN", "Last saved: 2 hours ago", "Resume" / "Start Over"*, **preserve all previously entered data**.

### §2.1.6 — Tier 3 (Mega)
- All Tier-2 requirements **plus address verification + utility bill + agent verification** (geo-tagged photo; checklist: confirm residence).
- Address scoring: **>80% auto-approve; 50–80% flag for agent visit** (scheduled *"within 3–5 working days, 9am–5pm"*); agent confirmation → **system upgrades user to Tier 3 automatically**.
- **Interim status:** *"User has Tier 2 limits until address verified."* Dashboard shows **"Mega Tier Pending: Address verification in progress."** Status trackable in profile.

### §2.2.1 — Dashboard
- **Tier level badge with upgrade prompt; transaction-limits display; security status indicator.**
- KYC status badge: **Verified / Pending / Limited.**
- Quick stats, rewards, security indicators (last login/device, KYC badge), system status (maintenance, online/offline).

### §2.2.4 — Tier Upgrade
- Eligibility check <5s with score breakdown; document upload validation (PDF/JPG/PNG, <10MB, quality); OCR (name/number/issue/expiry) with manual correction; automated flags (expired, mismatched names, poor quality).
- **Status updates at each stage: Submitted → Reviewing → Approved/Rejected** (real-time, with push notifications).
- **"User cannot skip tiers (must go 1→2→3)".**
- Notifications: Submitted ("Tier Upgrade Submitted … under review … Requirements: 3/4 complete … Expected decision: Within 24 hours"); Approved ("Tier Upgraded … New limits apply … Review period: 30 days (can downgrade)"); Rejected ("Upgrade Rejected - Needs Improvement … reapply in 7 days"); Reminder.
- **What constitutes an upgrade:** a persisted, reviewed, approved progression 1→2→3 with new limits.

### §2.3.1 — Profile
- BVN masked **"XXX-XXX-12345"** (last 5 digits); display requires authentication.
- **Tier shows progress to next tier: "60% to Pro Tier"; upgrade option if eligible.**
- KYC status icons: Green (✓), Yellow (⏳), Red (✗); profile completeness score with suggestions.

---

## C. TIER STATE & TRANSITION MODEL

### C.1 The 13 states traced separately (do NOT assume equivalence)

| # | State | Authoritative source | Field | Owning service | Persistence | API | JWT claim | Mobile representation | Gateway representation | PRD-aligned? |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | No tier selected | auth-service | `pendingTier=null`, `tier=null` | Auth | DB `users` | UserResponse | `tier: null` | `selectedTier=1` (default) → displayed as Tier 1 | `kycLevel=1` (default) → BASIC limits | ❌ (defaults invented) |
| 2 | Tier selected | auth-service | `pendingTier={BASIC,PRO,MEGA}` | Auth `selectTier` | DB `users` | `POST /auth/select-tier` | `tier: null` (not yet granted) | `user.pendingTier` → used as effective/display tier | not synced (no pendingTier in gateway) | ✅ (selection≠grant) |
| 3 | Tier pending | auth-service | `pendingTier` | Auth | DB | UserResponse | none | pendingTier; rendered as current (❌) | none | ⚠️ (not surfaced distinctly) |
| 4 | Tier requirements satisfied | auth-service | `KycVerification` flags | Kyc | DB | `/auth/kyc/status` | n/a | `basicRequirementsSatisfied` etc. | n/a | ✅ |
| 5 | Tier granted | auth-service | `tier` | `TierProgressionService` | DB `users` | UserResponse | **`tier: {BASIC,PRO,MEGA}`** | not mapped to a "granted" field; `selectedTier` overwritten with granted value | `kycLevel` updated on next token | ⚠️ (grant exists but mobile has no distinct granted-tier field) |
| 6 | Tier in JWT | auth-service | `claims.tier` | `JwtTokenProvider` | in-token | refresh/issue | **granted tier only** | read nowhere for routing | `UserSyncService.kycLevelFor` | ✅ |
| 7 | Tier presented by gateway | gateway | `User.kycLevel` (1/2/3) | `UserSyncService` | local DB | dashboard/profile | from JWT claim | n/a | kycLevel | ⚠️ (null→1 defect) |
| 8 | Tier displayed by mobile | mobile | `pendingTier ?? selectedTier ?? tierProvider` | `profile_screen`, `home_screen` | local | — | — | "Tier N" label | — | ❌ (conflates selected/pending with granted) |
| 9 | Tier limits applied | gateway | `TierLimits.forTier(kycLevel)` | `DashboardServiceImpl` | — | dashboard | — | — | BASIC for null | ❌ (P0) |
| 10 | Upgrade requested | auth-service | `pendingTier` (set) | `selectTier` | DB | `POST /auth/select-tier` | — | local-only simulation (`upgrade_tier_screen`) | `requestTierUpgrade` proxies selectTier | ⚠️ (mobile never calls it) |
| 11 | Upgrade under review | **nonexistent** | — | — | — | — | — | — | — | ❌ (no review lifecycle) |
| 12 | Upgrade approved | auth-service | `tier` granted | `TierProgressionService` | DB | — | granted tier | — | limits on next token | ⚠️ (auto-approve on KYC met; no human review stage) |
| 13 | Upgrade rejected | **nonexistent** | — | — | — | — | — | — | — | ❌ |

### C.2 Tier-transition matrix

| From | To | PRD | Backend | Mobile | Gateway | Status |
|---|---|---|---|---|---|---|
| None (fresh) | Tier 1 selected | explicit choice required | `pendingTier=BASIC` (no KYC gate — intent only) | `choose_tribe` → selectTier | n/a | ✅ |
| None (fresh) | **Tier 2/3 selected** | 1→2→3; cannot skip | **allowed** (only downgrade blocked) | allowed in UI | n/a | ❌ **BACKEND PRD CONTRADICTION — MANUAL UPDATE REQUIRED** |
| None | Basic granted | selfie + (BVN∨NIN) | `livenessVerified && (bvn||nin)` | — | — | ✅ |
| Basic | Pro granted | Basic + BVN∧NIN + ID doc | `highestMetTier` (bvn&&nin&&idDoc) | `proRequirementsSatisfied` | — | ✅ |
| Pro | Mega granted | Pro + address + agent | `address==VERIFIED` (poller) | `megaRequirementsSatisfied` | — | ✅ |
| Mega | — | cap | never downgrades | — | — | ✅ |
| Basic | Mega (direct upgrade request) | **forbidden** | selectTier allows (only blocks downgrade) | local UI allows any higher tier | requestTierUpgrade allows (target>current) | ❌ **BACKEND PRD CONTRADICTION — MANUAL UPDATE REQUIRED** |
| Any | (review states) | Submitted→Reviewing→Approved/Rejected | **absent** | absent | absent | ❌ |

---

## D. LIVENESS → BASIC TIER TRACE

### D.1 Mobile liveness lifecycle
1. `KycFlowManager` routes to `SelfieInstructionsScreen` when `!isSelfieVerified` (`kyc_flow_manager.dart:274,282,291`).
2. `SelfieInstructionsScreen` → `LivenessCaptureScreen` (`selfie_instruction.dart:162-168`).
3. `LivenessCaptureScreen` calls `livenessProvider.submit(image)` → **client-side Dojah** check via `LivenessVerificationService`/`DojahClient` (`liveness_provider.dart:61-90`).
4. On success the screen calls `updateKycStatus(isSelfieVerified: true)` — **LOCAL ONLY** (`liveness_capture_screen.dart:440-442`) — then pushes `IdVerificationScreen`.
5. `IdVerificationScreen` (`id_verification_controller.dart:52-71`) refuses BVN/NIN without the captured selfie (`"Please complete selfie verification first."`) and re-submits the selfie with `verifyBvn`/`verifyNin`.

**Key architectural fact:** the mobile liveness result is never persisted to the backend as a standalone liveness event. The backend re-derives `livenessVerified` from the selfie submitted *with* BVN/NIN. Harmless to the grant (backend still gates), but the mobile's "Identity Verified!" dialog can diverge from server state until the next `refreshKycStatus`.

### D.2 Backend lifecycle
1. `verifyBvn`/`verifyNin` → `DojahIdentityClient.verifyIdentity(idType, idNumber, selfieBase64)`.
2. `verifyIdentity` runs **liveness first**, **fail-closed**: `spoof` defaults `true` when the field is missing/malformed (`DojahIdentityClient.java:95-98`); `!configured` → MANUAL_REVIEW; `!live` → REJECTED "Liveness check failed".
3. Only if liveness passes does it call the BVN/NIN selfie-match endpoint; `match==false || confidence<90` → REJECTED.
4. `KycServiceImpl.applyResult` sets `livenessVerified=true` **only when `result.isVerified()`** (`KycServiceImpl.java:253`); top-level status → VERIFIED after first BVN∨NIN (`:256-257`).
5. `TierProgressionService.evaluateTierProgress` grants BASIC iff `livenessVerified && (bvn||nin)` (`TierProgressionService.java:73`); sets `registrationComplete=true` on BASIC grant (`:64-67`).
6. `JwtTokenProvider.generateAccessToken` mints `claims.tier = user.getTier().name()` — null until granted (`JwtTokenProvider.java:44`).

### D.3 Gateway lifecycle
1. `JwtAuthenticationFilter` → `UserSyncService.resolveFromClaims(claims)` parses `claims.get("tier")` (`UserSyncService.java:37`).
2. `kycLevelFor(null) → 1` (`UserSyncService.java:91`); refresh updates `kycLevel` **only when the claim tier is non-null** (`:72`).
3. `TierLimits.forTier(user.getKycLevel())` → `forTier(1)` = BASIC limits (`DashboardServiceImpl.java:140`).

### D.4 Explicit answer
> **Can a user who has NEVER completed liveness receive BASIC/TIER 1 as an authoritative server-side tier?**

**No.** `User.tier` is written in exactly one place in main source (`TierProgressionService.java:63`) and only after the liveness+ID gate above. There is no alternative path (register does not set tier; selectTier only sets `pendingTier`; no admin/bootstrap auto-grant). The Dojah gate is fail-closed. **The "Tier 1" the user experiences is a display/limits classification created by the mobile and gateway null-defaulting, not a server grant.**

---

## E. LOGIN → DASHBOARD GATE TRACE (navigation matrix)

| Entry point | File:line | Authenticated? | KYC/liveness check | Tier check | Dashboard? | PRD-aligned? |
|---|---|---|---|---|---|---|
| Splash (boot, session restore) | `splashscreen.dart:72-79` | ✅ | ✅ via `KycFlowManager` (selfie-first) | ✅ per-tier | only when per-tier reqs met | ✅ |
| Onboarding → signup → OTP → more details | `signup_more_details.dart:146` → `TribeScreen` | ✅ | ✅ | ✅ | via KycFlowManager | ✅ |
| choose_tribe continue | `choose_tribe.dart:68-71` | ✅ | ✅ → KycFlowManager | ✅ | via KycFlowManager | ✅ |
| tier_check screen | `agent/tier_check_screen.dart:112` | ✅ | ✅ → KycFlowManager | ✅ | via KycFlowManager | ✅ |
| **Login (passcode)** | **`login_page.dart:172-176`** | ✅ | ❌ **none** | ❌ | **direct `BottomNavBar`** | ❌ **P0** |
| Device-link success | `account_active.dart:83-86` | ✅ | ❌ none | ❌ | direct `BottomNavBar` | ⚠️ |
| Bill payment done | `bill_transaction_detail.dart:297` | ✅ | ❌ none | ❌ | direct `BottomNavBar` | ⚠️ |
| Legacy account-ready | `account_ready.dart:437-441` | ✅ | ❌ (assumes prior steps) | ❌ | direct `BottomNavBar` | ⚠️ |

**Conclusion:** there is **no single authoritative dashboard gate**. The boot path is correctly gated (Slice 6), but the **interactive login path bypasses it entirely** — a successful login currently *implies* nothing about KYC, yet still lands on the dashboard. **The PRD-required distinction (login must NOT imply KYC complete / Basic granted / Tier 1 granted) does not exist on the login path.** On the boot path the distinction exists and is honored.

**Session restoration (§20 Q8):** boot restores a cached session (cache-first) and fires `refreshKycStatus()` **unawaited** (`auth_provider.dart:106`). Routing still goes through `KycFlowManager`, which gates on the (possibly stale) cached flags. A stale cache carrying a local-only `isSelfieVerified=true` (set by the liveness screen without server confirmation) can transiently classify toward a later funnel step until the reconcile lands — but it cannot reach `complete` for Basic without also `isBvnVerified||isNinVerified`, so the dashboard is not reachable from boot for a genuinely unverified user. The real KYC bypass is **login**, not restoration.

---

## F. NULL TIER / DEFAULT TIER AUDIT (HIGH PRIORITY)

Every null→default mapping found:

| # | Layer | File:line | Mapping | Consequence |
|---|---|---|---|---|
| 1 | Mobile | `user_model.dart:295` | `selectedTier = _tierStringToInt(json['tier'])` | null server tier → `selectedTier=1` |
| 2 | Mobile | `user_model.dart:327-337` | `_tierStringToInt(null)` → `default: 1` | "BASIC" is the parse fallback for `null` |
| 3 | Mobile | `user_model.dart:62` | `selectedTier` constructor default `= 1` | fresh model is Tier 1 |
| 4 | Mobile | `profile_screen.dart:703-709` | `pendingTier ?? selectedTier ?? tierProvider.tierNumber` | unverified user → "Tier 1" |
| 5 | Mobile | `home_screen.dart:88,210` | `tierState.getTierObject().tierNumber` (local provider, default Basic) | dashboard header "Tier 1" |
| 6 | Mobile | `tier_provider.dart:82` | `TierState(currentTier: TierLevel.basic)` | default Basic |
| 7 | Mobile | `tier_provider.dart:92` | storage parse `orElse: () => TierLevel.basic` | default Basic |
| 8 | Gateway | `UserSyncService.java:91` | `kycLevelFor(null) → 1` | null JWT tier ⇒ Basic level |
| 9 | Gateway | `entity/User.java:69` | `private Integer kycLevel = 1;` | persisted default is BASIC |
| 10 | Gateway | `UserSyncService.java:72` | refresh skips update when claim tier null | kycLevel stays 1 |
| 11 | Gateway | `ProfileServiceImpl.java:43,64-67` | `kycVerified = kycLevel != null && kycLevel >= 1` | unverified → `tier:1, kycStatus:"verified"` |
| 12 | Gateway | `TierLimits.java:25-33` | `forTier(null) → UNVERIFIED` | **correct** branch, but **unreachable** via dashboard (value defaulted to 1 at #8/#9) |

**Per §6 checklist:**
1. Genuinely UNVERIFIED? — **Intended** at `TierLimits` (₦10k), but **never reached** through the real path.
2. Displayed as Basic? — **Yes** (mobile profile/home; gateway profile `tier:1`).
3. Treated as Basic for authorization? — **Yes** (gateway treats kycLevel=1 as Basic; profile `kycStatus:"verified"`).
4. Treated as Basic for transaction limits? — **Yes** (₦50k/₦50k) — see §G.
5. Treated as Basic in profile? — **Yes** (`tier:1`).
6. Included as BASIC in JWT? — **No** (backend mints `null`, never BASIC, for unverified).
7. Persisted as BASIC? — **Yes on the gateway** (`User.kycLevel` default 1); **no on the backend** (`User.tier` stays null).

---

## G. GATEWAY AUTHORIZATION & LIMITS AUDIT

### G.1 What each tier value actually does

| tier / claim | kycLevel (gateway) | Limits (`TierLimits`) | Profile |
|---|---|---|---|
| `null` (unverified) | **1 (BASIC)** | **₦50,000 / ₦50,000** | `tier:1, kycStatus:"verified"` ❌ |
| `BASIC` | 1 | ₦50,000 / ₦50,000 | `tier:1, kycStatus:"verified"` ✅ |
| `PRO` | 2 | ₦500,000 / ₦200,000 | `tier:2` ✅ |
| `MEGA` | 3 | ₦3,000,000 / ₦1,000,000 | `tier:3` ✅ |
| `pendingTier` | n/a (never synced/used) | no effect | absent ✅ (limits never advance on pending) |

### G.2 Explicit answer
> **Does an OTP-only / non-liveness-verified user actually receive Basic/Tier-1 transaction limits?**

**Yes.** A freshly registered user (server `tier=null`) presents a JWT with `tier: null`; `UserSyncService` persists `kycLevel=1`; `DashboardServiceImpl.buildWalletLimits` computes `TierLimits.forTier(1)` = **₦50,000 daily / ₦50,000 single** and the dashboard displays these limits; profile reports `tier:1, kycStatus:"verified"`.

**Classification: SECURITY/BUSINESS-RULE DEFECT, not a display bug.** An unverified user is granted the ₦50,000 Tier-1 envelope purely from the null-defaulting. (Note: hard *enforcement* of these limits on cash-in/cash-out/bills/transfers is currently a **no-op** — `EntryServiceImpl.checkTransactionLimits` is an empty stub — so the limits are representational today, but the representational/authorization layer already over-grants. Both defects are P0/P1.)

### G.3 Wallet / activation at gateway
- `ensureWallet` is called from exactly one place: `SettingsServiceImpl.provisionWalletBestEffort`, invoked **only on a tier-1 upgrade request** (`SettingsServiceImpl.java:249-251`). The primary onboarding path never triggers wallet creation; `registrationComplete` is ignored by the gateway; `CustomerOnboardingService` is an empty stub.

---

## H. TIER UPGRADE LIFECYCLE AUDIT

| Concern | Finding | Priority |
|---|---|---|
| Is upgrade persisted server-side from the UI? | **No.** `upgrade_tier_screen.dart:184` calls `tierProvider.notifier.upgradeTier(tier.level)` — a **local-only** simulation writing StorageService. No `POST /auth/select-tier`, no gateway `requestTierUpgrade`. | P1 |
| Backend upgrade intent | `selectTier` sets `pendingTier` and immediately evaluates; grant is **automatic** the moment KYC is met (PRD's *auto-KYC checks / auto-approve*). There is **no `Submitted → Reviewing`** stage and **no `Rejected`** state for upgrades. | P1 |
| Gateway upgrade path | `requestTierUpgrade` validates 1..3 and `target > current`, proxies `selectTier`, provisions wallet only for tier 1. Limits do not change during pending (only on next token with granted tier) ✅. | P2 |
| No-skip (1→2→3) | Not enforced. `selectTier` blocks only **downgrade** (`AuthServiceImpl.java:228-230`); a fresh user may select PRO or MEGA directly; Basic→Mega direct is permitted at every layer. **PRD §2.2.4 AC "User cannot skip tiers (must go 1→2→3)" violated.** | **P0/P1 — BACKEND PRD CONTRADICTION — MANUAL UPDATE REQUIRED** |
| Upgrade status lifecycle (Submitted/Reviewing/Approved/Rejected) | Does not exist anywhere (no field, no API, no UI, no push). | P1 |
| Wallet on upgrade | Only tier-1; no wallet provisioning for Pro/Mega upgrades (may be correct if wallet is account-level; needs product decision). | P2/Blocked |
| Payment (KudikitPayment) | Wallet provisioning API exists (`ensureWallet`), invoked only from gateway upgrade path. No account-activation orchestration. | P1 |
| Upgrade reflected in JWT/limits | Only after the granted tier is minted into a fresh token (next login/refresh). Latency is inherent to the claim; acceptable but worth noting. | P2 |

---

## I. PROFILE API / GATEWAY RECONCILIATION

### I.1 Existing gateway endpoints
- `GET /api/v1/profile` — returns `AccountInfo{tier=kycLevel, tierLabel, kycStatus, accountNumber, …}` + `VerificationInfo{bvn/nin/address}`.
- `POST /api/v1/profile/update-profile`; `GET /api/v1/profile/completeness`; `GET /api/v1/profile/referral`; profile-picture upload/update.

### I.2 Truthfulness vs PRD (§2.3.1)

| PRD profile item | Gateway today | Problem | Required change |
|---|---|---|---|
| Current (granted) tier | `tier = user.getKycLevel()` | For unverified = 1 (Basic) — **not granted** | Derive from granted tier; null ⇒ 0/"Unverified" |
| `kycStatus` | `kycLevel>=1 ⇒ "verified"` | Unverified reported "verified" | Gate on granted tier / registrationComplete; use Verified/Pending/Limited |
| Pending tier | **absent** | Cannot show "Mega Tier Pending" | Add `pendingTier` from auth-service (extend `AuthUserResponse` + sync) |
| Masked BVN/NIN | `masked: null` (coarse `bvn.verified = kycVerified`) | Not PRD-accurate; "XXX-XXX-12345" only on mobile | Backend can't mask (it stores hashes); keep masking in mobile or store masked form; **flag as manual/backend decision** |
| Address verification | `address.verified = kycLevel>=3` | Not accurate (no per-field address status) | Sync `addressStatus`/`AddressInfo` from auth-service |
| Tier progress "60% to Pro" | **absent** | — | Compute from verified requirement flags (auth-service is the source) |
| Upgrade state | **absent** | — | Depends on upgrade lifecycle (§H) |

**Rule applied:** the mobile UI must NOT be adapted to these incorrect gateway semantics. The gateway (and auth-service sync) is the component that must change.

---

## J. GPS / GEOLOCATION ARCHITECTURE AUDIT

GPS is **in scope and satisfied** by the Slice 6 abstraction. The architecture supports either provider without touching the address domain.

### J.1 Layering
- **Domain:** `GeoCoordinates` (pure lat/lng value type) — `geolocation_provider.dart:29-46`. The address flow (`verify_address.dart`, `AddressVerificationRequest`, backend `VerifyAddressRequest`/`KycVerification.addressLatitude/Longitude`, `DojahDocumentClient.AddressInfo`) only ever touches `GeoCoordinates`/primitive doubles.
- **Abstraction:** `abstract class GeolocationProvider` (`getCurrentCoordinates`, `getAddressFromCoordinates`, `getCoordinatesFromAddress`, `isAvailable`, `name`) — `geolocation_provider.dart:49-66`.
- **Option A (mobile):** `MobileGeolocationProvider` wraps the existing `GeoService` (geolocator + geocoding + permission handling) — `geolocation_provider.dart:70-120`, `geo_service.dart:22-116`. No existing GPS functionality was removed.
- **Option B (backend):** `BackendGeolocationProvider` is structurally complete; with no backend endpoint wired it resolves to `null`, triggering the manual-entry fallback — `geolocation_provider.dart:126-156`.
- **Selection:** build-time define `KUDIKIT_GEOLOCATION_SOURCE=mobile|backend` (`geolocation_provider.dart:162-171`). Switching providers requires **no change to address-domain logic**.
- **Backend:** Slice 6 BE-5 added `latitude`/`longitude` to `VerifyAddressRequest`, persisted `addressLatitude`/`addressLongitude` on `KycVerification`, and forwarded them in `DojahDocumentClient.AddressInfo`/`submitAddressVerification` — provider-agnostic, no business-logic coupling.

### J.2 Explicit answer (§20 Q18)
> Can GPS be switched between mobile-provider and backend-provider without changing address-domain logic?

**Yes.** The interface boundary (`GeolocationProvider` + `GeoCoordinates`) already decouples the address domain from `geolocator`/`geocoding`; the backend stores coordinates without depending on a specific provider. A future backend geolocation endpoint plugs into `BackendGeolocationProvider` with no domain change. **GPS was not removed and is not deferred.**

---

## K. BACKEND / GATEWAY RECONCILIATION REGISTER

### K.1 Backend (kudikit_auth_service)

| ID | PRD requirement | Current behavior | Required change | Owner | Priority | Manual update required? |
|---|---|---|---|---|---|---|
| BE-1 | No-skip 1→2→3 | `selectTier` blocks only downgrade; fresh user can select Pro/Mega; Basic→Mega direct allowed | Enforce sequential progression at selection (e.g., require current granted tier before selecting higher, or expose review flow) | Auth | P1 | **YES** (behavioral contract change; product decision needed on whether onboarding may target Mega directly) |
| BE-2 | Submitted→Reviewing→Approved/Rejected upgrade lifecycle | Only `pendingTier` (intent) + auto-grant on KYC met; no review/reject states | Add upgrade/review state model; map MANUAL_REVIEW & agent stages to PRD statuses | Kyc/Tier | P1 | **YES** |
| BE-3 | Tier-1 activation (PIN → CBA → NumBan → wallet) | No activation endpoint; `registrationComplete=true` on Basic grant only | Add activation orchestration (needs bank CBA + NumBan partner) | Onboarding | Blocked | **YES** (external integration) |
| BE-4 | `registrationComplete` as resume gate (PRD §2.1.5) | Set on Basic grant; never read as a resume/dashboard gate | Either expose as authoritative gate or document reliance on KYC flags | Auth | P2 | Partial |
| BE-5 | Liveness mandatory for Basic | Correct and fail-closed | — (no change) | Kyc/Dojah | — | No |
| BE-6 | JWT tier = granted only | Correct | — (no change) | Auth | — | No |
| BE-7 | Address auto-upgrade on agent confirm | `AddressVerificationPoller` re-evaluates | — (no change) | Kyc | — | No |
| BE-8 | Fresh-user default "No tier selected" ≠ Tier 1 | Backend correctly keeps `tier=null` | — (no change; the defect is at mobile/gateway) | Auth | — | No |

### K.2 Gateway (Kudikitgateway)

| ID | PRD requirement | Current behavior | Required change | Owner | Priority | Manual update required? |
|---|---|---|---|---|---|---|
| GW-1 | Unverified ≠ Basic limits | `kycLevelFor(null)→1`; `User.kycLevel` default 1 ⇒ **BASIC ₦50k limits for unverified** | Map null/absent granted tier ⇒ UNVERIFIED (₦10k); do not default to BASIC | Gateway | **P0** | **YES** |
| GW-2 | Profile truthfulness | `kycLevel>=1 ⇒ kycStatus:"verified"`, `tier:1` | Derive from granted tier; Verified/Pending/Limited | Gateway | P0/P1 | **YES** |
| GW-3 | Profile pending tier / address / progress | absent; `bvn/nin/address.verified` coarse; masked=null | Sync and expose `pendingTier`, `addressStatus`, requirement progress from auth-service | Gateway | P1 | **YES** |
| GW-4 | Transaction-limit enforcement | `EntryServiceImpl.checkTransactionLimits` is an **empty stub** | Implement limit checks on cash-in/cash-out/bills/transfers (after fixing GW-1 defaults) | Gateway | P0/P1 | **YES** |
| GW-5 | Wallet on activation/grant | `ensureWallet` only on tier-1 upgrade request; onboarding never triggers it | Trigger wallet provisioning on grant/activation; honor `registrationComplete` | Gateway | P1 | **YES** |
| GW-6 | `CustomerOnboardingService` | empty stub | Implement or remove | Gateway | P2 | Optional |

### K.3 Mobile (Kudikit)

| ID | PRD requirement | Current behavior | Required change | Priority |
|---|---|---|---|---|
| MO-1 | Dashboard gated on activation/KYC | `login_page.dart:172-176` → `BottomNavBar` directly | Route login through the same gate as boot (`KycFlowManager`/granted-tier check) | **P0** |
| MO-2 | Null server tier ≠ Tier 1 | `fromAuthResponse:295` maps null→1; `_tierStringToInt(null)→1` | Preserve null; never display selected/pending as granted | **P0** |
| MO-3 | Granted vs pending display | `profile_screen._effectiveTierNumber` returns pending/selected | Render granted tier; show pending separately ("(pending)") | P0/P1 |
| MO-4 | Home tier badge | `home_screen.dart:88,210` reads local tierProvider (default Basic) | Use granted tier from server | P1 |
| MO-5 | Upgrade wired to backend | `upgrade_tier_screen.dart:184` local-only simulation | Call `selectTier`/gateway upgrade; surface Submitted/Reviewing/Approved/Rejected | P1 |
| MO-6 | Liveness result authority | `liveness_capture_screen.dart:440` local-only `isSelfieVerified` | Optional backend persist; at minimum reconcile on boot (already done) | P2 |
| MO-7 | Boot reconcile race | `_checkAuthStatus` fires `refreshKycStatus()` unawaited | Await/re-evaluate before first route or after reconcile | P2 |
| MO-8 | Legacy funnel route | `confirm_info→transaction_pin→account_ready→BottomNavBar` | Unify behind KycFlowManager gate | P1 |
| MO-9 | Resume UX (§2.1.5 "Step X of 7") | Not implemented (behavioral resume works via KycFlowManager) | Add resume affordance per PRD (post-P0) | P2 |

---

## REGISTERS (§18) — PRD RECONCILIATION MATRIX

| # | Requirement | PRD | Backend | Gateway | Mobile | Status | Required Action | Owner |
|---|---|---|---|---|---|---|---|---|
| 1 | Tier selection is explicit, not auto-assigned (§2.1.2) | Explicit user choice; selection ≠ grant | `pendingTier` set by `selectTier` (intent only) | n/a | Defaults `selectedTier=1` for a null tier → implicit Basic | ⚠️ | Mobile: stop defaulting null→1; render granted tier (MO-2/MO-3) | Mobile |
| 2 | Basic = selfie + (BVN ∨ NIN); grant after KYC (§2.1.4) | Grant gated on liveness + ID | `TierProgressionService:73` correct, fail-closed | Correct (granted tier → limits) | Funnel correct; login bypasses it | ⚠️ | Mobile: route login through gate (MO-1) | Mobile |
| 3 | Tier-1 limits ₦50,000 only after grant (§2.1.4) | UNVERIFIED ≠ Basic | n/a | **null→Basic ₦50k (GW-1)** | — | ❌ P0 | Gateway: null ⇒ UNVERIFIED ₦10k (GW-1) | Gateway |
| 4 | Dashboard after activation; limited while CBA pending (§2.1.4) | Activation chain then dashboard | No activation endpoint | `ensureWallet` only on tier-1 upgrade | Primary funnel skips PIN/CBA/wallet | ❌ | Backend: activation orchestration (BE-3, **Blocked** external) | Backend/Blocked |
| 5 | Tier-2 = Basic + BVN ∧ NIN + valid ID (§2.1.5) | Cumulative requirements | `highestMetTier` correct | n/a | `proRequirementsSatisfied` correct | ✅ | — | — |
| 6 | Upgrade lifecycle Submitted→Reviewing→Approved/Rejected (§2.2.4) | Review states + notifications | **Absent** (BE-2) | Absent | Local-only simulation (MO-5) | ❌ | Backend: review state model; Mobile: wire upgrade UI | Backend + Mobile |
| 7 | No-skip 1→2→3 (§2.2.4) | Must progress sequentially | **Allows fresh Pro/Mega; Basic→Mega (BE-1)** | Allows (target>current) | Allows any higher tier | ❌ | Backend: enforce sequential selection (**MANUAL UPDATE**) | Backend |
| 8 | Mega interim = Tier-2 limits + "Mega Tier Pending" banner (§2.1.6) | Interim limits + banner | Address poller auto-upgrades | Never grants Mega limits while pending ✅ | `PENDING_AGENT_VISIT` = interim routing ✅; banner absent | ⚠️ | Mobile: dashboard banner (P2); Gateway: expose pending | Mobile |
| 9 | Address verification w/ agent (score/geo-tag) (§2.1.6) | >80 auto, 50–80 agent, auto-upgrade | Poller + lat/long persisted ✅ | n/a | GPS provider abstraction ✅ | ✅ | — | — |
| 10 | Dashboard tier badge + KYC badge (Verified/Pending/Limited) (§2.2.1) | Granted tier + true KYC badge | n/a | Profile reports `tier:1, kycStatus:"verified"` for unverified (GW-2) | Home header "Tier 1" for all (MO-4) | ❌ | Gateway profile truthfulness; Mobile granted-tier badge | Gateway + Mobile |
| 11 | Profile: masked BVN "XXX-XXX-12345", progress "60% to Pro", upgrade if eligible (§2.3.1) | Masked + progress + eligibility | Stores hashes only (can't mask server-side) | `masked:null`; no progress; no eligibility | Masked BVN/NIN present (Slice 6); no progress/eligibility | ⚠️ | Gateway: expose requirement progress; decide masking source | Gateway/Decision |
| 12 | Resume via `registration_complete` ("Step X of 7") (§2.1.5) | Resume screen + preserved data | Sets flag on Basic grant; not exposed as gate | Ignores flag | Behavioral resume via KycFlowManager; no resume screen | ⚠️ | Mobile: resume UX (P2); Backend: expose flag if needed | Mobile |
| 13 | User-tier limits enforced on transactions (§2.2.1) | Limits enforced | n/a | **Empty stub** (`EntryServiceImpl.checkTransactionLimits`) | — | ❌ | Gateway: implement enforcement (GW-4) | Gateway |
| 14 | JWT tier = granted tier only | — | Correct (`JwtTokenProvider:44`) | Consumes via `UserSyncService` | n/a | ✅ | — | — |
| 15 | Wallet created as part of activation (§2.1.4) | Wallet on activation | n/a | `ensureWallet` only on tier-1 upgrade; onboarding never triggers | — | ⚠️ | Gateway: provision on grant/activation (GW-5) | Gateway |

---

## DECISION GATE

### Answers to the 20 critical questions

**Q1. Can BASIC be granted without liveness?**
**Answer: No.** Backend evidence shows `TierProgressionService` requires `livenessVerified && (BVN || NIN)`, `livenessVerified` is only set on a successful Dojah verification (fail-closed — spoof defaults true), and `User.setTier` has a single write site (`TierProgressionService.java:63`). No alternative grant path exists (§D.2, §D.4).

**Q2. Is the observed Tier-1-without-liveness behavior a backend grant?**
**Answer: No.** The backend keeps `User.tier=null` (and therefore a null JWT tier claim) until the liveness+ID gate passes. The "Tier 1" the user experiences is a presentation/authorization classification created by mobile and gateway null-defaulting (§A, §D.4).

**Q3. Where does the login bypass occur?**
**Answer:** Mobile `login_page.dart:172-176` navigates directly to `BottomNavBar` after a successful passcode login, bypassing `KycFlowManager`. Secondary un-gated dashboard entries: `account_active.dart:83-86`, `account_ready.dart:437-441`, `bill_transaction_detail.dart:297` (§E).

**Q4. What happens when backend tier is null?**
**Answer:** No tier is granted server-side (`User.tier=null`). On mobile, `fromAuthResponse:295` / `_tierStringToInt(null)→1` set `selectedTier=1`, so profile/home render "Tier 1"; `pendingTier` may or may not be set (§F).

**Q5. What happens to gateway limits when tier is null?**
**Answer:** `UserSyncService.kycLevelFor(null)→1` and `User.kycLevel` default `1` cause `TierLimits.forTier(1)` to apply **BASIC limits (₦50,000 daily / ₦50,000 single)**. The intended UNVERIFIED (₦10,000) branch is unreachable through this path (§G).

**Q6. What does the gateway profile report for null tier?**
**Answer:** `ProfileServiceImpl:43,64-67` computes `kycVerified = kycLevel != null && kycLevel >= 1`, so an unverified user is reported as `tier:1, kycStatus:"verified"` (§G, §I).

**Q7. Is JWT tier itself trustworthy?**
**Answer:** Yes, as a transport. `JwtTokenProvider.java:44` mints the claim from the granted `user.getTier()` only — never BASIC before grant, pending never included. The untrustworthy behavior is the gateway's downstream null→BASIC defaulting, not the claim itself (§D.2, §G).

**Q8. Is mobile's Tier 1 display trustworthy?**
**Answer:** No, for unverified users. `selectedTier` defaults to 1, `_tierStringToInt(null)→1`, and `profile_screen._effectiveTierNumber:703-709` / `home_screen.dart:88,210` render selected/pending as the current tier, so an unverified user appears as Tier 1 (§F, §C.1 state #8).

**Q9. Is Basic KYC routing PRD-compliant?**
**Answer:** Partially. The funnel itself is compliant (selfie → BVN∨NIN; `KycFlowManager.classify` routes incomplete users to selfie). But Basic completion does NOT trigger the PRD's PIN → CBA → NumBan → wallet → activation chain; the primary funnel routes a complete Basic user straight to `BottomNavBar` (§B, §C.2, §12, PRD matrix #4).

**Q10. Is Pro KYC routing PRD-compliant?**
**Answer:** Requirements routing is compliant — `proRequirementsSatisfied` = Basic + BVN∧NIN + ID verified, and `KycFlowManager` funnels to ID upload. The PRD review lifecycle (Submitted → Reviewing → Approved/Rejected) and limited-functionality-during-review are not implemented (§B §2.1.5, §C.2, §H).

**Q11. Is Mega KYC routing PRD-compliant?**
**Answer:** Requirements routing is compliant (Pro + address; `PENDING_AGENT_VISIT` treated as the PRD interim). The "Mega Tier Pending: Address verification in progress" dashboard banner and gateway interim-state representation are absent (§B §2.1.6, §C.2, PRD matrix #8).

**Q12. Is no-skip enforced according to the PRD?**
**Answer:** No. `AuthServiceImpl.selectTier` blocks only downgrades, so fresh Pro/Mega selection and Basic→Mega direct upgrade requests are permitted. **PRD §2.2.4 contradiction — MANUAL UPDATE REQUIRED ON BACKEND** (§C.2, §H, §K.1 BE-1).

**Q13. Is upgrade lifecycle implemented?**
**Answer:** No. Mobile upgrade is a local-only simulation (`upgrade_tier_screen.dart:184` writes StorageService, no API call); backend has only `pendingTier` intent + auto-grant on KYC met; there are no Submitted/Reviewing/Approved/Rejected states and no notifications (§H, §K.1 BE-2).

**Q14. Is dashboard access correctly gated?**
**Answer:** No. The boot path is gated (splash → `KycFlowManager`), but the interactive login path bypasses the gate, so an OTP-only registrant can reach the full dashboard before KYC (§E, P0).

**Q15. Are transaction limits actually enforced?**
**Answer:** No. `EntryServiceImpl.checkTransactionLimits` is an empty stub; `TierLimits` only feed dashboard/profile display. Agent limits are the only enforced caps (§G.2, §K.2 GW-4).

**Q16. Is Mega pending/interim state represented correctly?**
**Answer:** Partially. Mobile routes `PENDING_AGENT_VISIT` as the PRD interim (Tier-2 routing) and the backend grants Mega only on `address==VERIFIED` (via the poller). The dashboard "Mega Tier Pending" banner and any gateway interim display are absent (§B §2.1.6, §C.2, PRD matrix #8).

**Q17. Is registration/resume fully PRD-compliant?**
**Answer:** No. The backend sets `registrationComplete=true` on Basic grant, but mobile does not read it as a resume/dashboard gate, and the PRD "Continue Your Registration / Step X of 7" resume screen is not implemented (behavioral resume via `KycFlowManager` only) (§B Returning User, §K.3 MO-9).

**Q18. Is GPS implementation currently aligned with the agreed architecture?**
**Answer:** Yes. The `GeolocationProvider`/`GeoCoordinates` abstraction (mobile + backend providers, build-time `KUDIKIT_GEOLOCATION_SOURCE` switch) and backend lat/long persistence keep the address domain provider-agnostic. GPS is in scope, not deferred (§J).

**Q19. What must be manually corrected on the backend because of PRD contradiction?**
**Answer:** No-skip 1→2→3 progression. `AuthServiceImpl.selectTier` permits fresh Pro/Mega selection and Basic→Mega requests (only downgrade is blocked), contradicting PRD §2.2.4. **MANUAL UPDATE REQUIRED ON BACKEND** (§C.2, §H, §K.1 BE-1). No other backend contradiction is directly supported by the evidence in this report.

**Q20. What is the exact minimum scope that must be completed before proceeding to broader tier-upgrade work?**
**Answer:** The P0 triad: (1) gateway null-tier truthfulness — null/ungranted ⇒ UNVERIFIED state/limits, truthful profile (GW-1/GW-2); (2) mobile login routed through the existing `KycFlowManager`/gating mechanism (MO-1); (3) mobile must not display null/pending as granted Tier 1 (MO-2/MO-3). After these, rerun the Slice 7 reconciliation audit before the broader P1/P2 tier-upgrade lifecycle.

### P0 — Must fix before broader Slice 7 tier-upgrade work

1. **Gateway null-tier truthfulness**
   - `null tier` must not become BASIC.
   - Null/ungranted users must receive the PRD-appropriate UNVERIFIED state/limits.
   - Gateway profile must not report `tier:1` / `kycStatus:"verified"` for an unverified user.
   - This is a gateway implementation correction (GW-1, GW-2).

2. **Mobile login KYC gate**
   - Login must not navigate directly to the dashboard for users who have not satisfied the PRD-required onboarding/KYC state.
   - Route authenticated users through the existing KycFlowManager/gating mechanism.
   - Do not redesign the flow (MO-1).

3. **Granted-tier vs pending/null-tier display**
   - Remove the semantic conversion of `null` into granted Tier 1.
   - Display only the actual server-granted tier as the granted tier.
   - Pending tier must remain pending and must not be represented as granted tier (MO-2, MO-3).

### MANUAL BACKEND UPDATES REQUIRED BY PRD

- **No-skip tier progression:** the backend currently permits fresh Pro/Mega selection and Basic→Mega upgrade requests because `AuthServiceImpl.selectTier` only blocks downgrade (`AuthServiceImpl.java:228-230`). This contradicts PRD §2.2.4 ("User cannot skip tiers (must go 1→2→3)") and must be **manually corrected on the backend** to enforce 1→2→3 progression (register BE-1).

*(No other existing backend behavior is demonstrated by this report to directly contradict an explicit PRD requirement. Missing features — e.g. the upgrade review lifecycle (BE-2) and the CBA/NumBan activation chain (BE-3) — are implementation gaps / externally blocked work, not contradictions.)*

### Classification

> **CONDITIONAL GO**

Progress to implementation **only for the P0 set** above (gateway null-tier truthfulness, mobile login KYC gate, granted-tier vs pending/null display). The system is **NOT healthy** for production on the current build: the dashboard-access bypass (P0), the null-tier⇒BASIC limit default (P0), and the no-op transaction-limit enforcement (P0/P1) violate PRD §2.1.4/§2.2.1/§2.2.4. Backend grant/liveness logic is sound and does not block the P0 work. After the P0 corrections, rerun the Slice 7 reconciliation audit before beginning the broader P1/P2 tier-upgrade lifecycle implementation.

---

## VERIFICATION OF READ-ONLY DISCIPLINE (§21)

- Source files modified by this investigation: **0**
- Tests changed: **0**
- Configuration changed: **0**
- Dependencies changed: **0**
- Files created: **1** (`Kudikit/SLICE_7_INVESTIGATION_REPORT.md`)

*Note: the working tree already contained 40 modified files (`git status`) — uncommitted work from prior slices (Slice 4B/5/6). None were touched by this investigation.*

---

## FINAL STATUS

INVESTIGATION STATUS: READ-ONLY — NO CODE MODIFIED

DECISION: CONDITIONAL GO

P0 BLOCKERS:
1. Gateway null-tier → UNVERIFIED/truthful profile and limits.
2. Mobile login → existing KYC gate.
3. Null/pending tier must not display as granted Tier 1.

MANUAL BACKEND UPDATE REQUIRED:
- Enforce PRD no-skip 1→2→3 progression.

NEXT STEP:
After the P0 corrections are implemented, rerun the Slice 7 reconciliation audit before beginning the broader tier-upgrade lifecycle implementation.
