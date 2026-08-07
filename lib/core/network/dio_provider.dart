// lib/core/network/dio_provider.dart
// ─────────────────────────────────────────────────────────────────────────────
// The single [DioClient] provider used by all services.
//
// Split out of the former core/providers/core_providers.dart during the core/
// migration. The singleton service providers it depends on live in
// core/singleton/service_providers.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/config/network_config.dart';
// kBaseUrl is re-exported by api_client.dart (from core/config/network_config.dart).
import 'package:kudipay/core/network/api_client.dart';
import 'package:kudipay/core/singleton/service_providers.dart';

/// The single [DioClient] instance used by all services.
///
/// Injects [StorageService] for auth-token interception and
/// [ConnectivityService] for offline guards. No other Dio/http wrapper
/// should be created elsewhere.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: AppConfig.baseUrl,
    storage: ref.watch(storageServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});
