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

## Feature migration — progress

Eight domains have now been relocated into `lib/features/<domain>/`, each as its own
green, per-domain commit (screens → `presentation/pages`, providers/notifiers →
`presentation/controllers`, models → `domain/entities`), with one-line barrel
re-export shims left at every legacy path so importers keep compiling unchanged:

`selfie · notification · tier · request · cashout · transaction · linkdevice · agent`

`flutter analyze` is clean after each. **Remaining legacy domains** to migrate the
same way: `address · bankdeposit · email · Identity · intro · onboarding · otp ·
passcode · profile · qrcode · splashscreen · support · ticket · tribe · homescreen`
plus their `provider/*` counterparts. Once every importer of a shim is repointed to
the canonical path, the shim files can be deleted.

> Note: the `request` domain used **relative** imports (`../../model/...`) rather than
> `package:` imports — these must be converted to absolute paths when moved, since
> barrel shims only cover `package:` imports. Watch for this in remaining domains.

## Recommendations (future scalability)

1. **Continue the feature migration** for the remaining domains listed above, using
   the same barrel-shim + per-domain-commit procedure. Run `flutter analyze` after
   **each** domain (not batched) — it catches broken relative imports immediately.

2. **Centralize the brand palette (biggest DRY win).** `AppColors.primaryTeal` is
   defined in `core/theme/app_theme.dart` but the raw literal `Color(0xFF069494)` is
   hardcoded **439 times across 90 files**. Replace with `AppColors.primaryTeal` in a
   dedicated, reviewed pass. Do the same for the other repeated hex literals
   (`0xFF9E9E9E`, `0xFF1A1A2E`, `0xFFF9F9F9`, …).

3. **Collapse the parallel state layer.** `provider/` (Riverpod providers) duplicates
   the role of `features/*/presentation/controllers`. Consolidate as each domain moves.

4. **Relocate stray state files.** `lib/usecases/selfie_state.dart` was moved into
   `features/selfie/domain` in this pass; `lib/usecases/passcode_state.dart` still
   belongs inside its feature (auth/passcode), not a top-level `usecases/`.

5. **Standardize directory names.** `presentation/Identity/` → `identity/`,
   `provider/Identity_verify/` → `identity_verify/`, `provider/P2P_transfer/` →
   `p2p_transfer/` (folder names are cosmetic but reinforce the convention).

6. **Wire up or remove the stubbed services.** `id_verification_services.dart` and the
   `_client`-injected notifiers have real logic behind commented-out API calls.
   Decide per service: connect to the live API, or drop if superseded.

## Remaining warnings
None. `flutter analyze` is clean.
