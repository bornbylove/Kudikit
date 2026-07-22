// lib/core/network/dio_interceptor.dart
// ─────────────────────────────────────────────────────────────────────────────
// Dio interceptors used by [DioClient] (core/network/api_client.dart).
//
// Extracted from the former config/dio_client.dart during the core/ migration.
//
//   • AuthInterceptor — injects the Bearer token (read lazily from
//     StorageService on every request) and clears auth on 401 responses.
//   • LogInterceptor  — debug-only request/response/error logging.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:kudipay/services/storage_services.dart';

/// Injects the `Authorization: Bearer <token>` header on every request.
///
/// The token is read lazily from [StorageService] per request, so it is always
/// fresh and the client never needs rebuilding when the token changes. A 401
/// response clears stored auth so the app routes to login on next startup.
class AuthInterceptor extends Interceptor {
  final StorageService _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 → clear stored auth so the app routes to login on next startup
    if (err.response?.statusCode == 401) {
      _storage.clearAuth();
    }
    handler.next(err);
  }
}

/// Debug-only logging of outgoing requests, responses, and errors.
///
/// Named [KudiLogInterceptor] to avoid clashing with Dio's built-in
/// `LogInterceptor`, which is exported from `package:dio/dio.dart`.
class KudiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[KudiDio] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
        '[KudiDio] ← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
        '[KudiDio] ✗ ${err.type} ${err.requestOptions.uri} — ${err.message}');
    handler.next(err);
  }
}
