// lib/core/singleton/service_providers.dart
// ─────────────────────────────────────────────────────────────────────────────
// Riverpod providers that expose the app's singleton infrastructure services.
//
// Split out of the former core/providers/core_providers.dart during the core/
// migration. The HTTP client provider now lives in core/network/dio_provider.dart.
//
// RULES:
//   1. Never access StorageService.instance / ConnectivityService.instance
//      directly. Always go through these providers.
//   2. Service classes should receive dependencies via constructor injection,
//      not by reading singletons internally.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/services/storage_services.dart';

/// Provides the singleton [StorageService] for all secure/shared-pref storage.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Provides the singleton [ConnectivityService] for internet checks.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService.instance;
  ref.onDispose(() => service.dispose());
  return service;
});
