# KudiPay — `core/` Consolidation

_Date: 2026-07-22 · Branch: `dev`_

Consolidates cross-cutting infrastructure that had been scattered across
`lib/config/`, `lib/services/`, `lib/provider/`, and `lib/routes/` into a single
`lib/core/` tree, matching an agreed target layout. Follow-through on
recommendation #3 of [REFACTOR_REPORT.md](REFACTOR_REPORT.md).

**No UI/UX or runtime behavior changed.** Each step was its own commit and
`flutter analyze` reported **No issues found!** after every step.

## Final `lib/core/` layout

```
core/
├── app/
│   ├── app_route.dart              (AppRouter)               ← core/navigation/
│   ├── app_routes.dart             (route constants + args)  ← core/navigation/   [D1]
│   ├── app_router_import.dart      (routing barrel, NEW)     replaces routes/app_route.dart [D2]
│   ├── navigation_helpers.dart                               ← core/navigation/   [D1]
│   └── cache_helper.dart           (SharedPreferences helper, NEW)                [B1]
├── config/
│   └── network_config.dart         (kBaseUrl)                ← config/env.dart
├── constants/                      (kept as-is)
│   ├── constant.dart
│   └── id_type.dart
├── extension/
│   └── string_extension.dart       (NEW)                                          [B1]
├── network/
│   ├── api_client.dart             (DioClient)               ← config/dio_client.dart
│   ├── dio_interceptor.dart        (AuthInterceptor, KudiLogInterceptor) split from dio_client
│   ├── dio_provider.dart           (dioClientProvider)       ← core/providers/     [D3]
│   ├── app_exception_handler.dart  (KudiException hierarchy) ← core/errors/exceptions.dart
│   │                                                          + services/api_services.dart aliases
│   └── api_reponse.dart            (ApiResponse<T>, NEW)                            [B1]
├── services/
│   ├── auth_background_services.dart (STUB)                                        [B2]
│   ├── biometric_services.dart       (STUB, needs local_auth)                      [B2]
│   └── notification/
│       ├── fcm_service.dart              (STUB, needs firebase_messaging)          [B2]
│       ├── fcm_background_handler.dart   (STUB, needs firebase_messaging)          [B2]
│       ├── notification_services.dart    (STUB, needs flutter_local_notifications) [B2]
│       └── notification_navigator_services.dart (STUB)                             [B2]
├── singleton/
│   ├── cache.dart                  (in-memory singleton cache, NEW)               [B1]
│   └── service_providers.dart      (storage/connectivity providers) ← core/providers/ [D3]
├── theme/                          (kept as-is — app_theme.dart, 120 importers)
│   └── app_theme.dart
└── utils/
    ├── jwt.dart                    (dependency-free JWT reader, NEW)              [B1]
    ├── device/device_utility.dart  (DeviceInfoService)       ← services/device_info_services.dart
    ├── formatters.dart             (kept as-is)
    ├── responsive.dart             (kept as-is)
    └── shared_widget.dart          (kept as-is)
```

## Steps (one commit each, analyzer green after each)

1. `config/env.dart` → `config/network_config.dart` (repointed the one re-export in dio_client).
2. `core/errors/exceptions.dart` + the deprecated aliases in `services/api_services.dart`
   → `network/app_exception_handler.dart` (10 importers repointed; both old files deleted).
3. `config/dio_client.dart` → `network/api_client.dart`; interceptors extracted to
   `network/dio_interceptor.dart` (16 importers). `_LogInterceptor` → `KudiLogInterceptor`
   to avoid clashing with Dio's built-in `LogInterceptor`. `lib/config/` removed.
4. `core/providers/core_providers.dart` split: `dioClientProvider` →
   `network/dio_provider.dart`; `storageServiceProvider` + `connectivityServiceProvider`
   → `singleton/service_providers.dart` (13 importers repointed precisely; old
   `provider/network/dio_provider.dart` shim deleted).
5. `services/device_info_services.dart` → `utils/device/device_utility.dart` (3 importers;
   class `DeviceInfoService` name unchanged).
6. `core/navigation/*` → `core/app/*`; added `app/app_router_import.dart` barrel replacing
   `routes/app_route.dart` (18 + 7 importers repointed; `lib/routes/` and `core/navigation/`
   removed).
7. Created the remaining target files (see B1/B2 below).

## Decisions applied

- **D1** — `app_routes.dart` (route constants, 18 importers) and `navigation_helpers.dart`
  (7 importers) weren't in the target list; kept and moved into `app/` alongside `app_route.dart`.
- **D2** — `app_router_import.dart` created as the public routing barrel
  (`export app_route; export app_routes;`), replacing the old `routes/app_route.dart` shim.
- **D3** — `network/dio_provider.dart` holds `dioClientProvider`; the storage/connectivity
  singleton providers moved to `singleton/service_providers.dart` (a needed addition beyond
  the target's `singleton/cache.dart`).
- **D4** — `StorageService` (`lib/services/storage_services.dart`) remains the source of truth
  for sensitive persistence. `cache.dart` (in-memory) and `cache_helper.dart` (SharedPreferences)
  are thin, separate conveniences — not replacements.
- **D5** — the 16 domain services under `lib/services/` were left in place; `core/services/`
  holds cross-cutting infra services only.

## New files

- **B1 (no new deps, functional):** `extension/string_extension.dart`,
  `network/api_reponse.dart`, `singleton/cache.dart`, `app/cache_helper.dart`, `utils/jwt.dart`.
- **B2 (stub only):** `services/auth_background_services.dart`, `services/biometric_services.dart`,
  and `services/notification/{fcm_service, fcm_background_handler, notification_services,
  notification_navigator_services}.dart`. Their methods throw `UnimplementedError` and document
  the pub dependency they need. Nothing imports them yet.

## Open follow-ups

- `network/api_reponse.dart` keeps the target's spelling; it looks like a typo for
  `api_response.dart` — rename if desired.
- To make the B2 stubs real, add the deps and wire startup:
  `firebase_messaging` (+ `Firebase.initializeApp()` in `main()`),
  `flutter_local_notifications`, `local_auth`, and a background scheduler
  (e.g. `workmanager`) for `auth_background_services`.
- Remaining cross-cutting state still outside `core/` (out of scope here):
  `lib/provider/{connectivity, refresh, add_money, funding}` and the `lib/provider/provider.dart`
  aggregator barrel; cross-cutting models under `lib/model/`.
