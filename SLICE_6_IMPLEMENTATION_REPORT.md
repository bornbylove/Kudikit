# SLICE 6 — PRD-ALIGNED TIER, KYC, GPS & PROFILE IMPLEMENTATION REPORT

- Date: 2026-08-17
- Scope: Kudikit Mobile (`Kudikit`), `kudikit_auth_service` (backend), `Kudikitgateway`
- Authority: **Kudikit Product Requirements Document V1.0** (the PRD is the #1 product authority; where backend/gateway/mobile behaviour contradicted it, the implementation corrected the code, never the PRD).

---

## A. What was implemented, by codebase

### A.1 Kudikit Mobile (`Kudikit`)

| File | Change | Register |
|---|---|---|
| `lib/model/user/kyc_status.dart` | Added `rejectionReason`, `idDocumentRejectionReason`, `addressRejectionReason` to `KycStatusSummary` (fromJson/toJson) so the server's reason reaches the status surface. | MO-3 |
| `lib/model/user/user_model.dart` | Added the three reason fields (ctor/copyWith/copyWithKyc/toJson/fromAuthResponse/fromJson); added `basicRequirementsSatisfied`, `proRequirementsSatisfied`, `megaRequirementsSatisfied`, `isTierComplete(int)` helpers. | MO-2 |
| `lib/services/auth_services.dart` | Added `selectTier({required int tierNumber})` → `POST /auth/select-tier` (`{tier: BASIC|PRO|MEGA}`, parsed via `UserModel.fromAuthResponse`); added `getProfile()` → `GET /profile` (Gateway, raw `data` map); `verifyAddress` now accepts optional `latitude`/`longitude`. | MO-1, MO-5, MO-6 |
| `lib/services/geolocation_provider.dart` (NEW) | `GeoCoordinates` pure value; `GeolocationProvider` abstraction; `MobileGeolocationProvider` (wraps existing `geo_service.dart`); `BackendGeolocationProvider` (prepared, resolves null); `geolocationProvider` Riverpod provider selected via `KUDIKIT_GEOLOCATION_SOURCE` dart-define (default `mobile`). geolocator/geocoding imports stay confined inside the mobile provider. | MO-5 |
| `lib/provider/auth/auth_provider.dart` | Added `selectTier(int)` (server call + saveUserModel + publish); lat/long passthrough in `verifyAddress`; **boot-time KYC reconciliation**: `_checkAuthStatus` fires `unawaited(refreshKycStatus())` after a cache-first restore. | MO-1, MO-4 |
| `lib/presentation/kyc/kyc_flow_manager.dart` | Rewrote routing to be **tier-aware per the PRD**: completion is evaluated per tier, not from top-level `KycStatus` (which flips to VERIFIED after just BVN or NIN); `effectiveTier` is server-authoritative (`pendingTier` → `selectedTier` → tierProvider fallback); `KycHoldState` + `holdState`/`holdReason`; `_KycStatusScreen` replaces the dead loading hold (Refresh Status; Try Again on rejected) with the server reason; Mega `PENDING_AGENT_VISIT` is the PRD interim tier → dashboard. | MO-2, MO-3 |
| `lib/presentation/tribe/choose_tribe.dart` | Tier selection now calls the server: `_onContinue` invokes `authProvider.notifier.selectTier(_selectedTierNumber)` (best-effort, non-fatal) before local persistence. | MO-1 |
| `lib/presentation/splashscreen/splashscreen.dart` | Authenticated users always route through `KycFlowManager` (tier-aware) instead of `isKycComplete ? HomeScreen : KycFlowManager`. | MO-2 |
| `lib/main.dart` | `MyApp` is now a `ConsumerStatefulWidget` + `WidgetsBindingObserver`; `didChangeAppLifecycleState` → `refreshKycStatus()` on resume. | MO-4 |
| `lib/presentation/profile/profile_screen.dart` | Header badge replaced hardcoded "Verified" with `_buildKycBadge`/`_kycStatusBadge` (live: Verified / Under review / Verification failed / Verification expired / KYC in progress / Address verification in progress); `_effectiveTierNumber` is server-authoritative; tier card shows **pending** when `pendingTier > granted`; BVN/NIN rows now show masked values + verification state. | MO-6 |

### A.2 KudikitGateway (`Kudikitgateway`)

No code changes required. Verification confirmed:

- `util/TierLimits` already implements PRD grant-tier limits: TIER_1 ₦50k/₦50k, TIER_2 ₦500k/₦200k, TIER_3 ₦3M/₦1M, and **null/granted tier → UNVERIFIED ₦10k/₦10k** (so a user stuck at `tier=null` gets UNVERIFIED, never the selected tier's limits). Correct as-is.
- `SettingsServiceImpl.requestTierUpgrade` proxies `AuthServiceClient.selectTier` and only `ensureWallet` for tier-1. Correct as-is.
- `ProfileController`/`ProfileResponseDTO` expose `account.tier`, `account.kycStatus`, `verification.{bvn,nin}.{verified,masked}`, `verification.address.status` — consumed by MO-6's `getProfile()`.

### A.3 kudikit_auth_service (backend)

| File | Change | Register |
|---|---|---|
| `service/impl/TierProgressionService.java` | **BE-1 (no-skip + PRD interim tiers) + BE-3 (registrationComplete)**: `evaluateTierProgress` now grants the **highest met tier ≤ pendingTier** (cumulative: BASIC → PRO → MEGA), never above the selected tier, never downgrades. Previously it only granted `pendingTier` directly, so a Mega-target user sat at `tier=null` (UNVERIFIED limits) until address verified. Now they are granted BASIC as soon as Basic is complete and **PRO as the PRD interim tier** while the address agent visit is in flight. `registrationComplete=true` is set the moment BASIC is granted (PRD 2.1.5 resume semantics). | BE-1, BE-3 |
| `dto/request/VerifyAddressRequest.java` | Added optional `latitude`, `longitude` (Double). | BE-5 |
| `entity/KycVerification.java` | Added `addressLatitude`, `addressLongitude` columns. | BE-5 |
| `integration/DojahDocumentClient.java` | `AddressInfo` record now carries optional latitude/longitude; `submitAddressVerification` includes them when present. | BE-5 |
| `service/impl/KycServiceImpl.java` | `verifyAddress` persists lat/long on the entity and forwards them to the Dojah address submission. | BE-5 |

---

## B. PRD reconciliation table

| PRD requirement | Slice 5 gap found | Slice 6 resolution | Status |
|---|---|---|---|
| Tier 1 Basic = liveness + (BVN **OR** NIN) | Mobile gated Basic funnel on BVN-only logic; completion keyed off top-level `KycStatus` | Basic funnel now requires selfie + BVN OR NIN; completion evaluated per tier | IMPLEMENTED |
| Tier 2 Pro = Basic + BVN **AND** NIN + ID | Top-level VERIFIED (set after BVN or NIN) short-circuited Pro to the dashboard | Pro completion = selfie + BVN AND NIN + ID verified; top-level VERIFIED no longer authoritative for Pro/Mega | IMPLEMENTED |
| Tier 3 Mega = Pro + address | Address step never surfaced for Mega; `PENDING_AGENT_VISIT` hit a dead loading hold | Mega funnel includes the address+utility-bill step; `PENDING_AGENT_VISIT` = PRD interim tier → dashboard (Tier-2 limits) | IMPLEMENTED |
| No tier skipping, backend authoritative | `selectTier` set `pendingTier` but only granted the exact pending tier (stuck at null) | Backend grants highest met tier ≤ pendingTier, never above, never downgrades; mobile is display-only | IMPLEMENTED |
| Tier selection server-authoritative | `choose_tribe` never called the server | `POST /auth/select-tier` now wired into tier selection | IMPLEMENTED |
| Async KYC states visible + actionable | REJECTED / MANUAL_REVIEW / EXPIRED / rejected ID / rejected address → generic loading hold | `_KycStatusScreen` with server reason + Refresh Status + Try Again (rejected only) | IMPLEMENTED |
| KYC reconciliation on boot/resume | `_checkAuthStatus` was cache-first with no refresh | Boot `unawaited(refreshKycStatus())` + app-lifecycle resume refresh | IMPLEMENTED |
| GPS captured with address (optional) | Address form had no coordinate capture | GPS provider abstraction; "Use my location"/"Change"; coordinates optional; lat/long sent to backend | IMPLEMENTED |
| Live profile (badge, pending tier, masked BVN/NIN) | Badge hardcoded "Verified"; no BVN/NIN display; tier shown as granted | Live badge, `pending` indicator, masked BVN/NIN rows | IMPLEMENTED |
| Registration / resume (`registrationComplete`) | Backend never set it for real users | Set when BASIC is granted; mobile resume retained until server-side proof replaces it | IMPLEMENTED |
| Dashboard/limits semantics | — | Gateway `TierLimits` verified correct (grant-tier limits, null → UNVERIFIED); no change needed | VERIFIED |
| PIN → CBA account → NumBan → wallet → activation | No CBA/NumBan integration exists anywhere | Audit only — see C.5 (BLOCKED) | BLOCKED |

---

## C. Backend reconciliation register

| # | Item | Status | Notes |
|---|---|---|---|
| BE-1 | Enforce no-skip + interim tiers server-side | **IMPLEMENTED** | `TierProgressionService.highestMetTier` grants highest met tier ≤ `pendingTier`; tested (10 unit tests). |
| BE-2 | `selectTier` authorisation (registered user, tier in 1..3, no downgrade) | **VERIFIED** (pre-existing, correct) | No change needed. |
| BE-3 | `registrationComplete` set on Basic completion | **IMPLEMENTED** | Set in `TierProgressionService` when BASIC is granted. |
| BE-4 | Rejection reasons surfaced to clients | **IMPLEMENTED** | `GET /auth/kyc/status` returns the full `KycVerification` entity which already serialises `rejectionReason`, `idDocumentRejectionReason`, `addressRejectionReason`; mobile parses them (BE-4 deferred-client-side no longer needed). |
| BE-5 | Address request carries optional lat/long (persisted + sent to Dojah) | **IMPLEMENTED** | DTO, entity columns, `verifyAddress`, `AddressInfo`. |
| BE-6 | Grant-tier limits vs pending tier | **VERIFIED** | Gateway `TierLimits` keyed on granted tier; pending shown only as display state. |
| BE-7 | Address poller `PENDING_AGENT_VISIT → VERIFIED` grants MEGA | **VERIFIED** | `evaluateTierProgress` runs from the poller path; new grant logic yields MEGA once address VERIFIED. |
| BE-8 | Wallet/account activation audit | **REQUIRES BACKEND FOLLOW-UP** | See D-gaps / C.5. |

### C.5 PIN → CBA account → NumBan → wallet → activation — BLOCKED

No CBA (commercial-bank-account) integration, no NumBan integration, and no activation endpoint exist in `kudikit_auth_service`. The gateway's `KudikitPaymentClient.ensureWallet` only creates a wallet for tier-1. **This item is BLOCKED on product/bank partnerships and is out of Slice 6 scope** — it was audited, not fabricated. Recommend a dedicated wallet/CBA slice with explicit product decisions.

---

## D. GPS architecture

```
Address flow (verify_address.dart)
        │  depends ONLY on
        ▼
   GeolocationProvider (interface)
        ├── MobileGeolocationProvider ──wraps──> GeoService (geolocator + geocoding)
        └── BackendGeolocationProvider ──prepared──> future backend geolocation API (resolves null today)
        ▲
   geolocationProvider (Riverpod)  ←  KUDIKIT_GEOLOCATION_SOURCE dart-define ("mobile" default)
```

- **Domain purity**: `GeoCoordinates` is the only geolocation type the address domain touches. `geolocator`/`geocoding`/`google_maps_flutter` imports remain confined inside `MobileGeolocationProvider` / `GeoService`.
- **Optionality**: permission denied / service disabled / backend unreachable all resolve to `null` — the address form always falls back to manual entry and never blocks submission.
- **Switchable**: `flutter run --dart-define=KUDIKIT_GEOLOCATION_SOURCE=backend` swaps sources with zero address-flow changes.
- **Transport**: coordinates are optional fields on `VerifyAddressRequest`, persisted on `KycVerification` (`addressLatitude`/`addressLongitude`) and forwarded to the Dojah address submission.

---

## E. Profile integration

- `AuthService.getProfile()` → `GET /profile` (Gateway `ProfileResponseDTO`, same DioClient/base URL as the auth domain).
- `profile_screen.dart` renders: live KYC badge (from `user.kycStatus`/`addressStatus`), server-authoritative tier (`pendingTier → selectedTier → tierProvider`), **pending** chip when `pendingTier > granted`, and masked BVN/NIN rows (masked digits + verified state).
- Rejection/expiry reasons for the badge and status surface come from `GET /auth/kyc/status` via `refreshKycStatus()` → `copyWithKyc`.

---

## F. Tier state model (effective)

```
Routing/display tier (server-authoritative):
  effective = user.pendingTier            // POST /auth/select-tier result
            else user.selectedTier        // granted tier from UserResponse.tier
            else tierProvider.currentTier // legacy/cached fallback

Granted tier (backend, cumulative):
  Basic  = livenessVerified && (bvnVerified || ninVerified)
  Pro    = Basic && bvnVerified && ninVerified && idDocumentStatus == VERIFIED
  Mega   = Pro  && addressStatus == VERIFIED
  Interim: targeting Mega with addressStatus == PENDING_AGENT_VISIT → granted PRO (Tier-2 limits)

Never granted above pendingTier; never downgraded.
```

---

## G. Tests

### Mobile (`flutter test`) — **196 tests, 0 failures** (baseline 175 → +21)
| Suite | Change |
|---|---|
| `test/kyc_flow_manager_test.dart` | Rewritten for PRD tier-aware routing (was 10 tests → 20): per-tier completion, NIN-only Basic, BVN-AND-NIN Pro, Mega requirements, PENDING_AGENT_VISIT interim, top-level-VERIFIED-not-completion, hold states, holdState/holdReason, effectiveTier. |
| `test/geolocation_provider_test.dart` (NEW) | 6 tests: GeoCoordinates value equality, backend-provider null semantics, mobile error→null mapping, default provider selection. |
| `test/auth_services_test.dart` | +5 tests: selectTier request shape + tier mapping, getProfile raw map, verifyAddress lat/long (sent + omitted). |
| `test/kyc_status_test.dart` | +1 test: rejection reasons survive the JSON round-trip. |
| `test/auth_provider_test.dart` | Updated for MO-4 (boot reconciliation fires `GET /auth/kyc/status`). |

`flutter analyze` — **0 errors, 470 issues** (baseline 468 issues / 0 errors; the +2 are info-level from new code following existing conventions).

### Backend (`mvn test -DskipITs`) — **22 tests, 0 failures** (baseline 12 → +10)
New `TierProgressionServiceTest`: Basic grant, NIN-only Basic, no-grant-without-basic, Pro-as-interim-while-Mega-address-pending, Mega-only-on-verified-address, never-above-selected-tier, never-downgrades, no-op-when-already-granted, no-op-without-pending-tier, user-not-found.

### Gateway (`mvn test -DskipITs`) — **13 tests, 0 failures** (no changes).

---

## H. Remaining gaps / open decisions

| # | Item | Status / owner |
|---|---|---|
| D1 | GPS capture UX: the coordinate is captured once per submission (no continuous tracking). Product to confirm whether re-capture is desired after a rejected address. | Open product decision |
| D2 | CBA account / NumBan / wallet activation. No bank integration exists. **BLOCKED** on partnerships — recommend a dedicated slice. | Backend/product, next slice |
| D3 | Rejection retry policy: `_KycStatusScreen` shows "Try Again" for rejected states (re-submit). No arbitrary retry limits imposed (none in PRD). | Open product decision |
| D4 | Interim-limit display: a Mega-target user granted PRO while the agent visit is pending is on Tier-2 limits. The dashboard reads the granted tier from the server, so limits are correct; the profile card shows the pending tier. Confirm product wants an explicit "pending upgrade" banner on the dashboard. | Open product decision |
| D5 | `getProfile()` is fetched by the profile screen; the dashboard still relies on the cached UserModel. A follow-up could reconcile the dashboard on resume. | Minor follow-up |
| D6 | Backend `KycStatusSummary` (embedded in `UserResponse`) does not carry the rejection reasons (only the full `/auth/kyc/status` entity does). If a future flow needs reasons immediately after select-tier/login, add them to `AuthServiceImpl.toKycStatusSummary`. | Follow-up (low priority) |
| D7 | `registrationComplete` is now server-set; mobile local resume (`user.dart`/splash) still guards as a fallback. Remove the local fallback once a device-reconcile proof (register/select-tier returning the flag reliably) is verified end-to-end. | Follow-up |