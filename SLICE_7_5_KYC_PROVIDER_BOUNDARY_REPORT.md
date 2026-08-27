# SLICE 7.5 — KYC PROVIDER BOUNDARY HARDENING REPORT

Status: **COMPLETE**

Scope boundary: read-only audit → fix the KYC *provider* boundary → regression-verify. No Slice 8 feature work was started.

---

## A. Executive Summary

Slice 7.5 closes the one remaining KYC **provider** boundary violation: the mobile app
called the KYC vendor (Dojah) **directly** to run a liveness check during onboarding, while
every other KYC operation already routed through `kudikit_auth_service`. That direct call
was both a security/architecture violation (vendor credentials shipped in the mobile binary)
and a functional duplicate (the authoritative liveness + selfie-match check already runs
server-side inside `verify-bvn` / `verify-nin`).

After a read-only investigation (mobile + auth-service + gateway + PRD), this slice:

1. Removed the mobile direct-Dojah path entirely (client, exceptions, service wrapper, model,
   config, dead enum, affected tests).
2. Rewired the selfie-capture step to be a **local capture-only** stage that forwards the
   captured image to the existing auth-service BVN/NIN flow, which owns all provider calls.
3. Removed the mobile Dojah credentials/config that were the boundary's "key" exposure.
4. Added the previously-missing backend test coverage pinning the provider-boundary
   invariants (`KycServiceImplTest`, `DojahIdentityClientTest`).
5. Documented the two PRD gaps found (selfie persistence, hardcoded sandbox credentials) and
   a set of dead-code P2 cleanups — none of which change behavior in this slice.

No application logic moved out of the auth service; the auth service was already the single
KYC provider boundary. No new API endpoint was invented.

---

## B. Scope & Boundary Definition

Target architecture (unchanged, now fully true):

```
Mobile (Kudikit)  ──→  kudikit_auth_service  ──→  Dojah (identity/liveness/doc/address)
```

Invariants enforced by this slice:

- **I1 (Single boundary):** the mobile app never calls a KYC provider directly and never
  holds provider credentials or a provider HTTP client.
- **I2 (No false claims):** the mobile never presents a liveness/verification result it did
  not obtain from the auth service. The capture step is capture-only.
- **I3 (Fail-closed):** the auth service refuses to auto-verify when the provider is
  unconfigured or unavailable, and rejects spoofed/insufficient-match selfies.
- **I4 (No invention):** no new endpoints or requirements are added; PRD gaps are
  documented, not silently implemented in a different shape.

Out of scope (deliberately): Slice 8 tier-upgrade lifecycle, CBA/NumBan checks, transaction
limits, notifications, UI redesign. The dead mock `SelfieCaptureScreen` is left untouched
(P2 cleanup item, not in the onboarding funnel).

---

## C. Investigation — Authoritative Context (read-only)

- PRD (`Kudikit_Product Requirements Document-V.1.pdf`, extracted to
  `/var/folders/__/12_k87k11c17tcst8hl_53yx9849_9/T/opencode/prd_text.txt`, 84 pages) is the
  #1 authority.
- **Tiers:** Tier 1 = selfie + (BVN **OR** NIN); Tier 2 = + BVN **AND** NIN + ID document;
  Tier 3 = + address/agent visit + utility bill.
- **Liveness/selfie:** the PRD's "BVN validation" call is *BVN number + selfie image*. The
  server performs the anti-spoof/liveness gate and the selfie↔registry match. There is **no**
  standalone "liveness endpoint" requirement, so none was invented.
- **Data captured:** the captured selfie is a PRD-mandated data element (7-year compliance
  retention, stored encrypted). This is currently **not** persisted server-side (see F.2).

### C.1 Mobile audit — where the provider is called

| Path | Provider call | Boundary status |
|---|---|---|
| `KycFlowManager → SelfieInstructionsScreen → LivenessCaptureScreen` | `DojahClient` direct `/api/v1/ml/liveness` | ❌ **VIOLATION (fixed)** |
| `LivenessCaptureScreen → IdVerificationScreen → IdVerificationController.verifyBvn/verifyNin` | auth-service `/auth/kyc/verify-bvn`/`-nin` | ✅ correct |
| `upload_ID.dart → authProvider.verifyIdDocument` | auth-service `/auth/kyc/verify-id-document` | ✅ correct |
| `verify_address.dart → geolocationProvider → authProvider.verifyAddress` | auth-service `/auth/kyc/verify-address` (GPS captured on-device, provider-abstracted) | ✅ correct |
| `api_services.dart /verify-bvn-nin` | gateway-era dead call | ✅ dead code |

Details of the violation:
- `lib/services/identity/dojah_client.dart` (DojahClient) + `dojah_exceptions.dart` +
  `liveness_verification_service.dart` (wrapper) + `identity_verification_type.dart` (dead)
  + `lib/model/identity/liveness_response.dart`.
- Credentials shipped in the binary: `lib/config/api_config.dart` read `DOJAH_APP_ID` /
  `DOJAH_SECRET_KEY` dart-defines with a default sandbox base URL.
- `LivenessCaptureScreen` called `livenessProvider.submit(image)` → DojahClient →
  Dojah, and on any 200 claimed **"Identity Verified!"** in a dialog and called
  `updateKycStatus(isSelfieVerified: true)` — a **local-only** cache write (never a server
  call), before navigating to the ID step. The BVN/NIN step then re-ran liveness
  server-side → the mobile claim was both unverifiable and duplicated.
- `updateKycStatus` is local-optimistic only; server truth is applied via
  `applyKyc`/`refreshKycStatus`; `UserModel.isSelfieVerified` derives from the server
  `livenessVerified` field when server data is present.

### C.2 Auth-service audit — already the single boundary ✅

`KycController` exposes `/api/v1/auth/kyc/{verify-bvn, verify-nin, verify-id-document,
verify-address, status}`. Every operation terminates at Dojah server-side:

- `DojahIdentityClient.verifyIdentity("bvn"|"nin", id, selfie)` runs **liveness first**
  (`/api/v1/ml/liveness/`, anti-spoof gate) then the registry selfie-match
  (`/api/v1/kyc/bvn/verify` | `/api/v1/kyc/nin/verify`).
- `DojahDocumentClient.analyzeDocument` / `analyzeUtilityBill` / `submitAddressVerification`.
- Fail-closed: unconfigured → `MANUAL_REVIEW`; provider unavailable → `MANUAL_REVIEW`;
  spoofed liveness → `REJECTED`; selfie mismatch → `REJECTED`; malformed liveness body
  defaults `spoof=true`.
- Liveness outcome is persisted on `KycVerification` (`livenessVerified`,
  `livenessConfidence`, `livenessVerifiedAt`).
- The image payloads (selfie, ID doc, utility bill) are uploaded to S3
  (`S3StorageService.upload`) and the vendor is handed a short-lived pre-signed URL
  (`presignGetUrl`, 15 min) — credentials never leave the server.

### C.3 Gateway audit — not a second KYC boundary ✅

The gateway has no KYC controller and no Dojah references; it only consumes `kycLevel`.
Legacy dead DTOs remain (`VerifyBVNRequestDTO` with `selfieId`, `ShuftiProCallbackDTO`,
`LoginResponseDTO.selfieFile`) with no controller references — P2 cleanup only.

### C.4 Liveness duplication — classification

The mobile direct liveness call is both **B (legacy mobile implementation)** and
**C (accidental duplicate)** of the server-side check. Because the PRD embeds liveness in
verify-bvn/verify-nin and the auth service already implements exactly that, the mobile path
was **removed**, not relocated. No `/auth/kyc/liveness` endpoint was created (would be an
invented requirement).

---

## D. Changes Made — Mobile (Kudikit)

All changes are removal/rewire only; no new screens, no UI redesign.

1. **`lib/provider/identity/liveness_provider.dart`** — rewrote `LivenessNotifier` as a
   capture-only state machine: `startCapturing`, `imageCaptured(path)`, `retake`, `reset`.
   No `submit`, no `livenessPassed`, no network, no provider references. The captured
   `imagePath` is retained solely for the BVN/NIN submission step.
2. **`lib/model/identity/liveness_state.dart`** — `LivenessStatus` reduced to `initial /
   capturing / imageCaptured`; removed `checkingLiveness / success / failure`,
   `livenessPassed`, `livenessProbability`.
3. **`lib/presentation/selfie/liveness_capture_screen.dart`** — rewire: capture →
   preview (Retake / **Continue**) → `Navigator.pushReplacement(IdVerificationScreen())`.
   Removed the Dojah submit call, the "Identity Verified!" success/failure dialogs, and the
   `updateKycStatus(isSelfieVerified: true)` local write. No liveness claim is made here.
4. **`lib/config/api_config.dart`** — removed `dojahAppId`, `dojahSecretKey`,
   `dojahBaseUrl`, `isDojahConfigured` and the dart-define documentation. Provider
   credentials no longer exist in the mobile app.
5. **`lib/core/utils/image_base64_util.dart`** — comment/doc updated: the utility now serves
   auth-service KYC payloads (no longer "Dojah liveness").
6. **Deleted (dead direct-provider code):**
   - `lib/services/identity/dojah_client.dart`
   - `lib/services/identity/dojah_exceptions.dart`
   - `lib/services/identity/liveness_verification_service.dart`
   - `lib/services/identity/identity_verification_type.dart`
   - `lib/model/identity/liveness_response.dart`
7. **Deleted tests** for the removed code: `test/dojah_client_test.dart`,
   `test/liveness_response_test.dart`.
8. **`test/liveness_provider_test.dart`** — rewritten to pin the capture-only invariant
   (6 tests): no success/verified state exists, no provider calls, image retained for the
   BVN/NIN step, reset clears state.

**Mobile network behavior after this slice:** the selfie step makes **zero** outbound calls.
The only KYC calls are to the auth service (`/auth/kyc/verify-bvn | verify-nin |
verify-id-document | verify-address | status`).

---

## E. Changes Made — kudikit_auth_service (tests only)

No production code was changed in the auth service this slice — it was already the single
boundary. The missing verification coverage was added:

1. **`src/test/java/com/kudikit/auth/service/impl/KycServiceImplTest.java`** (18 tests) —
   pins the service-level boundary contract:
   - BVN: success persists hashed BVN / vendor reference / raw response, sets
     livenessVerified + confidence, sources `user.fullName` from the registry, never
     overwrites an existing name, rejects on liveness failure, rejects on selfie mismatch,
     routes unconfigured provider to `MANUAL_REVIEW`, tolerates unparseable DOB, creates a
     fresh `PENDING` row when none exists.
   - NIN: success sets NIN details + `VERIFIED`, mismatch rejects.
   - ID document: valid+name-match → `VERIFIED` (with S3 upload/presign flow); invalid →
     `REJECTED` + 400; name mismatch / missing reference name → `MANUAL_REVIEW`.
   - Address: requires completed BVN/NIN first; accepted → `PENDING_AGENT_VISIT` with GPS
     coordinates forwarded to the vendor submission and applicant name sourced from
     `user.fullName`; unavailable bill → `REJECTED`; stale bill → `REJECTED`; vendor
     rejection propagates.
   - Tier progression is triggered on BVN/NIN success and on ID-document resolution.
2. **`src/test/java/com/kudikit/auth/integration/DojahIdentityClientTest.java`** (9 tests) —
   pins the client contract with a fake `DojahHttpClient` (recorded call order, no network):
   - Unconfigured → `MANUAL_REVIEW`, vendor never called.
   - **Liveness gate runs first**: spoofed liveness rejects and the registry call is never
     made (verified by call order `[/api/v1/ml/liveness/]` only).
   - Unavailable liveness endpoint → `MANUAL_REVIEW`.
   - Selfie mismatch / below-threshold match → `REJECTED` with the vendor reference and
     confidence retained.
   - Verified only when live + registry match ≥ threshold (90).
   - NIN endpoint + `birthdate` field handling; BVN endpoint + `date_of_birth` field.
   - Hard liveness error → fail-closed `MANUAL_REVIEW`; hard registry error → fail-closed
     `REJECTED` with the vendor message; malformed liveness body → fail-closed.

---

## F. Findings Classification

### F.1 P0 — Security / architecture (fixed this slice)

| # | Finding | Resolution |
|---|---|---|
| P0-1 | Mobile called Dojah directly (liveness) bypassing the auth service; duplicate of the server-side check | Removed (Section D.1–D.8) |
| P0-2 | Mobile shipped Dojah credentials/config (API keys readable from the binary) | Removed (D.4) |
| P0-3 | Mobile claimed "Identity Verified!" from a vendor response it couldn't verify | Removed (D.3); server remains sole authority |

### F.2 P1 — PRD gap / configuration (documented, NOT silently changed)

| # | Finding | Recommendation |
|---|---|---|
| P1-1 | **MANUAL BACKEND UPDATE REQUIRED BY PRD:** the captured selfie is not persisted server-side. PRD "Data Captured" requires the selfie stored encrypted on S3 (7-year compliance). Today `verify-bvn`/`verify-nin` only retain the match/liveness outcome, and the selfie is passed to Dojah without a stored copy. | Tracked; must be implemented (server-side persistence of the selfie on S3 with encryption at rest) before production compliance sign-off. Not implemented here because it changes provider-facing behavior and belongs with Slice 8's KYC lifecycle work. |
| P1-2 | Hardcoded Dojah sandbox credentials in `kudikit_auth_service/src/main/resources/application.yml` (env-var defaults). | Restrict to env-only (no defaults), rotate the sandbox secret, keep values out of VCS. Not changed in this slice to avoid breaking local dev. |

### F.3 P2 — Dead code (cleanup only, not required)

| # | Finding |
|---|---|
| P2-1 | `lib/presentation/selfie/selfie_capture_screen.dart` — dead mock screen (not in funnel); still calls `updateKycStatus`. |
| P2-2 | Gateway legacy DTOs: `VerifyBVNRequestDTO` (selfieId), `ShuftiProCallbackDTO`, `LoginResponseDTO.selfieFile`; `AsyncConfig` Shufti comment. |
| P2-3 | `lib/services/api_services.dart` `/verify-bvn-nin` — gateway-era dead endpoint. |

---

## G. Test Results

| Suite | Before (Slice 7) | After (Slice 7.5) | Status |
|---|---|---|---|
| Mobile `flutter test` | 211 | 189* | PASS (0 failures) |
| Mobile `flutter analyze` | 470 issues / 0 errors | 468 issues / 0 errors | PASS (0 errors) |
| `kudikit_auth_service` `mvn test` | 22 | 49 | PASS (0 failures) |
| `Kudikitgateway` `mvn test` | 27 | 27 (unchanged) | PASS (0 failures) |

\* Mobile count decreased because tests for deleted direct-Dojah code were removed and the
rewritten `liveness_provider_test.dart` (6 tests) is smaller. No production behavior tests
were dropped; the auth-service suite grew by 27 tests (18 service + 9 client).

New backend invariants now enforced by tests: single-boundary routing, fail-closed provider
behavior, liveness-before-registry ordering, GPS coordinate forwarding, name sourcing from
the government registry, no overwrite of verified names, tier-progression triggering.

---

## H. Regression Verification

- `flutter test` — all 189 pass (full suite, including Slice 6/7 regression tests:
  tier semantics, KYC verify contract, flow manager, geolocation, auth provider, KYC status).
- `flutter analyze` — 0 errors; issues reduced 470 → 468 (net −2 with no new issues in
  changed files).
- `mvn test` (auth service) — 49 pass, including the pre-existing `AdminServiceImplTest` /
  `TierProgressionServiceTest` / security & config suites.
- `mvn test` (gateway) — 27 pass, untouched.
- Diff reviewed: only the intended files were modified/deleted this slice; no unrelated
  source changes. The remaining modified/untracked files in all three repos are prior-slice
  work still uncommitted.

---

## I. PRD Reconciliation

| PRD requirement | Status after Slice 7.5 |
|---|---|
| Tier 1 = selfie + (BVN OR NIN) | ✅ Mobile captures selfie → auth-service verify-bvn/nin (liveness + selfie-match) |
| BVN validation API takes BVN + selfie image | ✅ Implemented server-side (`DojahIdentityClient.verifyIdentity`) |
| Liveness as anti-spoof at capture | ✅ Capture is local; authoritative anti-spoof runs server-side (fail-closed) |
| Tier 2 = BVN AND NIN + ID document | ✅ Untouched, server-routed |
| Tier 3 = address/agent visit + utility bill | ✅ Untouched, server-routed, GPS forwarded |
| Selfie stored encrypted (S3, 7-year retention) | ⚠️ **MANUAL BACKEND UPDATE REQUIRED BY PRD** (F.2 P1-1) — not yet implemented |
| No provider credentials in the mobile client | ✅ Removed (was the P0 fix) |

---

## J. Security Notes

- Removed provider API credentials from the mobile app (attack surface reduction).
- Auth-service Dojah calls keep using short-lived pre-signed S3 URLs; images are uploaded
  server-side only.
- **Remaining recommendation (not changed):** `application.yml` contains Dojah sandbox
  credential defaults; make them env-only and rotate before production (F.2 P1-2).

---

## K. Risk / Trade-off Assessment

- **Risk of change:** low — the change is removal of a redundant call plus screen rewire; the
  authoritative check was already server-side. BVN/NIN UX is unchanged (user still reaches
  the ID step with a captured selfie).
- **Trade-off:** the selfie step no longer gives any immediate "selfie verified" feedback;
  verification feedback now comes from the BVN/NIN step (server truth). This matches PRD
  semantics (liveness is validated with BVN/NIN, not standalone).
- **Provider dependency:** the server already handled provider failures fail-closed; tests
  now lock that behavior in.

---

## L. Backward-Compatibility & Migration

- `LivenessNotifier` public surface is smaller (methods removed). Only `LivenessCaptureScreen`
  used the removed API, and it was updated in the same change. No other callers existed
  (verified by grep).
- No database schema changes; no new endpoints; no gateway changes.
- The `imagePath` contract between capture and the BVN/NIN step is preserved.

---

## M. Deliverables

1. Mobile: direct-Dojah path removed; capture-only selfie step; provider config removed.
2. Mobile tests rewritten/deleted to match (all green).
3. `KycServiceImplTest` (18) + `DojahIdentityClientTest` (9) added in `kudikit_auth_service`.
4. This report (`SLICE_7_5_KYC_PROVIDER_BOUNDARY_REPORT.md`).

---

## N. Verification Checklist (manual)

- [x] `flutter analyze` → 0 errors
- [x] `flutter test` → 189/189 pass
- [x] `kudikit_auth_service` `mvn test` → 49/49 pass
- [x] `Kudikitgateway` `mvn test` → 27/27 pass
- [x] No `Dojah`/provider references remain in mobile `lib/` (except explanatory comment)
- [x] No invented `/auth/kyc/liveness` endpoint
- [ ] (Manual) Selfie capture → Continue → ID screen on a native device/emulator
  (KYC calls to the auth service are not expected to work from Chrome)

---

## O. Environment / Config Notes

- Mobile no longer needs `DOJAH_APP_ID`/`DOJAH_SECRET_KEY` dart-defines — they are gone.
- Auth-service Dojah config remains env-driven: `DOJAH_APP_ID`, `DOJAH_SECRET_KEY`,
  `dojah.base-url`, `dojah.match-confidence-threshold` (default 90).

---

## P. Files Changed — Summary

**Mobile (Kudikit):**
- Modified: `lib/provider/identity/liveness_provider.dart`, `lib/model/identity/liveness_state.dart`,
  `lib/presentation/selfie/liveness_capture_screen.dart`, `lib/config/api_config.dart`,
  `lib/core/utils/image_base64_util.dart`, `test/liveness_provider_test.dart`
- Deleted: `lib/services/identity/dojah_client.dart`, `dojah_exceptions.dart`,
  `liveness_verification_service.dart`, `identity_verification_type.dart`,
  `lib/model/identity/liveness_response.dart`, `test/dojah_client_test.dart`,
  `test/liveness_response_test.dart`

**kudikit_auth_service:**
- Added: `src/test/java/com/kudikit/auth/service/impl/KycServiceImplTest.java`,
  `src/test/java/com/kudikit/auth/integration/DojahIdentityClientTest.java`

**Kudikitgateway:** none.

---

## Q. Open Items / Follow-ups

| # | Item | Owner |
|---|---|---|
| Q1 | **MANUAL BACKEND UPDATE REQUIRED BY PRD:** persist captured selfie on S3 (encrypted, 7-year retention) with `verify-bvn`/`verify-nin` (F.2 P1-1) | Next slice |
| Q2 | Make Dojah credentials env-only + rotate sandbox secret (F.2 P1-2) | Ops/security |
| Q3 | Delete dead mock `SelfieCaptureScreen` + gateway Shufti-era DTOs + dead `api_services.dart` endpoint (P2) | Any future slice |
| Q4 | Mobile manual test on native device/emulator (N) | QA |

---

## R. Final Decision & Next Slice

**Verdict: COMPLETE.** The KYC provider boundary is now single-path and fail-closed; the
mobile client holds no provider credentials and makes no provider calls; the liveness
duplication is removed; the missing server-side boundary tests are added and green.

**Slice 8 (tier-upgrade lifecycle + KYC compliance persistence) may begin**, with two
carried requirements: (Q1) server-side selfie persistence per PRD and (Q2) env-only Dojah
credentials. Slice 8 must NOT reintroduce a direct provider call on mobile, and must keep
the fail-closed semantics now pinned by tests.
