# KudiPay — Stabilization & Cleanup Report

_Date: 2026-07-10 · Branch: `dev`_

## Summary

The project was already past the "won't compile" stage — the prior stabilization
commits had cleared every merge conflict and build-breaking error. This pass took
it from **112 analyzer issues → 0** (`flutter analyze` reports *No issues found!*),
removed dead/duplicate code, modernized deprecated APIs, and documented the
architecture situation for a safe, incremental migration.

No UI/UX behavior was changed. No working feature was removed.

## Starting state

- **269 Dart files**, `flutter analyze` = **112 issues** (0 errors, all info/warning).
- **0 merge-conflict markers** anywhere in the repo (already resolved).
- Half-migrated architecture: a modern clean-arch `features/` layer coexisting with
  a legacy flat `presentation/ · model/ · provider/ · services/` layer, bridged by
  intentional barrel/shim files.

## Fixes applied

### 1. Mechanical lints — `dart fix` (75 fixes, 48 files)
`use_super_parameters` (20), `curly_braces_in_flow_control_structures` (13),
`unnecessary_import` (8), `unused_element_parameter` (8),
`unnecessary_to_list_in_spreads` (5), `prefer_const_constructors_in_immutables` (2),
`prefer_final_fields` (1), `no_leading_underscores_for_local_identifiers` (1).

> ⚠️ `dart fix`'s `unused_element_parameter` rule introduced **5 new compile errors**
> by stripping constructor params that back still-used `final` fields
> (`_ShimmerBox.radius`, `_DetailRow.valueColor` ×2, `_PrimaryButton.isLoading`,
> `_Category.articleCount`). Each was corrected by inlining the field's constant
> default — zero behavior change.

### 2. Dead code
- **Deleted** `lib/model/user/user_verification.dart` — an isolated, unimported
  duplicate of the `UserVerificationData`/`IdentificationType` types that live in
  the newer `services/id_verification_services.dart`.
- **Deleted** `errors.txt` (560 KB stale analyzer dump, accidentally committed).
- **Removed** orphaned helper `_buildIcon` in `link_device_screen.dart`.

### 3. Preserved scaffolding (documented, not deleted)
Kept with explanatory `// ignore` comments because they are intentional DI wiring or
captured state for pending integration — deleting them would break constructors or
lose in-progress features:
- `_client` `DioClient` fields in `cable_tv_provider`, `electricity_provider`,
  `bill_service` (used only in adjacent stubbed live-API calls).
- `_idDocument` / `_selfie` in `verify_id.dart` (captured for pending submit).
- `_showReportSheet` + `_ReportIssueSheet` in `support_screen.dart`
  (fully-built "report issue" sheet, entry point pending re-wiring).

### 4. Deprecated API modernization
- **geolocator**: `desiredAccuracy` / `timeLimit` → `locationSettings: LocationSettings(...)`
  in `geo_service.dart` and `device_info_services.dart`.
- **flutter_secure_storage**: removed the deprecated `encryptedSharedPreferences: true`
  (now a no-op auto-migrated by the plugin) in `storage_services.dart` and
  `transaction_pin_service.dart`.

### 5. Correctness — `BuildContext` across async gaps
Guarded every flagged site (11 across 6 files) with the correct `context.mounted`
check (or `if (!mounted) return;`) — prevents "used after dispose" crashes in
`upload_document_screen`, `bulk_transfer_upload_file_screen`, `business_setup_step3`,
`verify_otp_email_screen`, `data_sync`, `get_verification_code_screen`.

### 6. Logging & naming
- `print(...)` → `debugPrint(...)` in `email_change_services` and
  `notification_preference_services` (release-safe).
- Renamed non-conforming files (all imports updated):
  `chooseID.dart → choose_id.dart`, `upload_ID.dart → upload_id.dart`,
  `P2P_transfer_provider.dart → p2p_transfer_provider.dart`.
- `_ReceiptAppBar` → `_receiptAppBar` (function, not a type).
- BVN/NIN enum: documented `// ignore_for_file: constant_identifier_names`
  (legitimate Nigerian identity acronyms).

### 7. Formatting
`dart format lib` — 12 files reformatted.

## Verification
- `flutter pub get` — ✅ succeeds.
- `flutter analyze` — ✅ **No issues found!** (was 112).
- `flutter build apk --debug` — see final status in the session summary.

---

## Architecture findings

The codebase is **mid-migration** between two structures:

| Layer | Dirs | Files | Status |
|-------|------|------:|--------|
| Modern (clean arch) | `config/ core/ features/ shared/` | ~84 | 5 domains migrated: auth, bills, kyc, transfer, wallet |
| Legacy (flat) | `presentation/ model/ provider/ services/ usecases/ routes/` | ~183 | ~115 screens + 26 providers + 22 models still here |

The two are bridged by **intentional barrel/shim files** (`routes/app_route.dart`
re-exports the canonical router; `model/auth/auth_state.dart` shims to
`features/auth/domain`). Routing is cleanly split into `app_route.dart` (router
logic) vs `app_routes.dart` (route-name constants) — **not** a duplicate.

## Feature migration — status: screens 100% complete

**Every screen has been relocated into `lib/features/<domain>/`.** `lib/presentation/`
now contains only one-line barrel re-export shims — no real code. There are **31
feature domains**, each migrated as its own green, per-domain commit (screens →
`presentation/pages`, providers/notifiers → `presentation/controllers`, models →
`domain/entities`), with shims left at every legacy path so importers compile
unchanged. `flutter analyze` is clean and the app builds after every step.

Domains migrated in this effort: `selfie · notification · tier · request · cashout ·
transaction · linkdevice · agent · address · bankdeposit · email · intro · onboarding ·
otp · passcode · profile · qrcode · splashscreen · support · tribe · homescreen ·
transactionpin · identity · ticket · kyc · signup · account_ready · transfer` (plus the
pre-existing `auth · bills · wallet`).

Notable handling:
- **`request`** used **relative** imports (`../../model/...`) — converted to `package:`
  paths on move, since barrel shims only cover `package:` imports.
- **`ticket`** is a self-contained module — moved wholesale (subtree intact) with its 2
  external importers repointed directly (no shim needed).
- **`PasscodeState`** was duplicated in `usecases/` and `features/auth/domain/`;
  consolidated into `features/passcode/domain`, both old copies now shims.
- Domain **providers** for `bills` (bill/cable_tv/electricity), `wallet`, and
  `linkdevice` (device_linking) were consolidated into their features too.

### Remaining (state layer only — no screens left)
Cross-cutting infrastructure providers intentionally left in `lib/provider/` because
they are **not** domain features and belong in `core/`: `connectivity`, `network/dio`,
`refresh`, the `provider.dart` aggregator barrel, plus `add_money`/`funding` (wallet-
adjacent, boundary needs a decision) and cross-cutting models (`bankmodel`, `device`,
`user`, `addmoney`). These need dedup/ownership review, not a mechanical move.

## Recommendations (future scalability)

1. **Delete the shims once importers are repointed.** Every legacy `presentation/`,
   `provider/`, and `model/` path is now a shim. In a follow-up, repoint each importer
   to the canonical `features/` path (grep-and-replace, verify with `analyze`), then
   delete the shim files — this removes `lib/presentation/`, `lib/usecases/`, and most
   of `lib/model/` and `lib/provider/` entirely.

2. **Centralize the brand palette (biggest DRY win).** `AppColors.primaryTeal` is
   defined in `core/theme/app_theme.dart` but the raw literal `Color(0xFF069494)` is
   hardcoded **439 times across 90 files**. Replace with `AppColors.primaryTeal` in a
   dedicated, reviewed pass. Do the same for the other repeated hex literals
   (`0xFF9E9E9E`, `0xFF1A1A2E`, `0xFFF9F9F9`, …).

3. **Finish collapsing the parallel state layer.** Most domain providers now live in
   `features/*/presentation/controllers`. The remainder in `lib/provider/` is either
   cross-cutting infra (→ move to `core/`: connectivity, network/dio, refresh, the
   `provider.dart` barrel) or wallet-adjacent (`add_money`, `funding` — decide whether
   they belong to `features/wallet` or their own feature).

4. **Relocate stray state files.** `lib/usecases/` is now empty of real code
   (`selfie_state.dart` → `features/selfie/domain`, `passcode_state.dart` →
   `features/passcode/domain`, both shimmed); the directory can be deleted once its two
   shims are repointed.

5. **Standardize directory names.** ✅ Done — the non-conforming `Identity/`,
   `IDdocument/`, `Identity_verify/`, and `P2P_transfer/` directories were deleted and
   their importers repointed to the lowercase `features/identity` and
   `features/transfer` paths. No capitalized directories remain under `lib/`.

6. **Wire up or remove the stubbed services.** `id_verification_services.dart` and the
   `_client`-injected notifiers have real logic behind commented-out API calls.
   Decide per service: connect to the live API, or drop if superseded.

## Remaining warnings
None. `flutter analyze` is clean.
