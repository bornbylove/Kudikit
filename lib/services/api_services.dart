// lib/services/api_services.dart
// ─────────────────────────────────────────────────────────────────────────────
// DEPRECATED — This file exists only for backward compatibility.
//
// The old ApiService singleton has been fully replaced by DioClient.
// Only the exception type aliases remain so that existing catch clauses
// in presentation files (signup.dart, login_page.dart, etc.) continue
// to compile while they are migrated incrementally.
//
// New code should:
//   • Use DioClient via dioClientProvider for HTTP calls
//   • Catch KudiNetworkException instead of NoInternetException
//   • Catch KudiTimeoutException instead of KudiPayTimeoutException
// ─────────────────────────────────────────────────────────────────────────────

import 'package:kudipay/core/errors/exceptions.dart';

/// @deprecated — use [KudiNetworkException] from core/errors/exceptions.dart.
typedef NoInternetException = KudiNetworkException;

/// @deprecated — use [KudiTimeoutException] from core/errors/exceptions.dart.
typedef KudiPayTimeoutException = KudiTimeoutException;
