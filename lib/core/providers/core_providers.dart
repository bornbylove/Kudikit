// lib/core/providers/core_providers.dart
// ─────────────────────────────────────────────────────────────────────────────
// Canonical Riverpod providers for core infrastructure services.
//
// These providers are the SINGLE source of truth for:
//   • StorageService    — encrypted auth tokens, passcodes, user data
//   • ConnectivityService — real-time internet connectivity checking
//   • DioClient         — the sole HTTP client for all API calls
//
// RULES:
//   1. Never access StorageService.instance or ConnectivityService.instance
//      directly. Always use ref.watch(storageServiceProvider) etc.
//   2. All service classes should accept their dependencies via constructor
//      injection, NOT by reading singletons internally.
//   3. Feature-level providers belong in their own files under lib/provider/.
//      Only infrastructure goes here.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/config/env.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/services/storage_services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Storage
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the singleton [StorageService] for all secure/shared-pref storage.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

// ─────────────────────────────────────────────────────────────────────────────
// Connectivity
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the singleton [ConnectivityService] for internet checks.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService.instance;
  ref.onDispose(() => service.dispose());
  return service;
});

// ─────────────────────────────────────────────────────────────────────────────
// HTTP Client
// ─────────────────────────────────────────────────────────────────────────────

/// The single [DioClient] instance used by all services.
///
/// Injects [StorageService] for auth-token interception and
/// [ConnectivityService] for offline guards. No other Dio/http
/// wrapper should be created elsewhere.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: kBaseUrl,
    storage: ref.watch(storageServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});
