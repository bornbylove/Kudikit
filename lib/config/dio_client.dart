// lib/config/dio_client.dart
// ─────────────────────────────────────────────────────────────────────────────
// Single, authoritative HTTP client for KudiPay.
//
// REPLACES:
//   • lib/config/api_client.dart   (raw http.Client wrapper)
//   • lib/services/api_services.dart (Dio singleton with duplicated methods)
//
// USAGE:
//   // In a Riverpod provider:
//   final myServiceProvider = Provider<MyService>((ref) {
//     final client = ref.watch(dioClientProvider);
//     return MyService(client);
//   });
//
//   // In a service method:
//   final response = await _client.get('/transactions');
//   final response = await _client.post('/auth/login', data: body);
//
// TOKEN MANAGEMENT:
//   The DioClient holds no token itself. Instead, the AuthInterceptor reads
//   the token lazily from StorageService on every request. This means:
//     - No need to rebuild the provider when the token changes.
//     - Token is always fresh (handles refresh scenarios later).
//     - 401 responses auto-clear storage and bubble up as KudiUnauthorizedException.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/api_config.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/services/session_events.dart';
import 'package:kudipay/services/storage_services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConnectivityChecker — the one method DioClient actually needs from
// ConnectivityService, extracted as an interface so tests can supply a
// trivial fake instead of the real connectivity_plus/internet_connection_
// checker_plus-backed singleton (which needs platform channels and makes
// real network calls — exactly what a deterministic unit test must avoid).
// ─────────────────────────────────────────────────────────────────────────────

abstract class ConnectivityChecker {
  Future<bool> hasInternetConnection();
}

// ─────────────────────────────────────────────────────────────────────────────
// Typed exceptions — catch these specifically in providers/notifiers
// ─────────────────────────────────────────────────────────────────────────────

class KudiNetworkException implements Exception {
  final String message;
  const KudiNetworkException([this.message = 'No internet connection.']);
  @override
  String toString() => message;
}

class KudiTimeoutException implements Exception {
  final String message;
  const KudiTimeoutException(
      [this.message = 'Request timed out. Please try again.']);
  @override
  String toString() => message;
}

class KudiUnauthorizedException implements Exception {
  final String message;
  const KudiUnauthorizedException(
      [this.message = 'Session expired. Please log in again.']);
  @override
  String toString() => message;
}

class KudiServerException implements Exception {
  final String message;
  final int? statusCode;
  const KudiServerException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class KudiApiException implements Exception {
  final String message;
  final int? statusCode;
  const KudiApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Interceptor — injects Bearer token on every request, and on a 401
// attempts a single-flight token refresh + retry before giving up.
//
// `_refreshDio` is a bare Dio instance (no interceptors) used only for the
// refresh-token call and the retried original request — reusing `_dio` here
// would re-enter this same interceptor and could recurse forever.
// ─────────────────────────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final StorageService _storage;
  final Dio _refreshDio;

  _AuthInterceptor(this._storage, this._refreshDio);

  static const List<String> _noRefreshPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/send-otp',
    '/auth/verify-otp',
    '/auth/refresh-token',
    '/auth/logout',
    '/auth/forgot-passcode',
  ];

  // Single-flight guard: concurrent 401s share one in-progress refresh
  // instead of each firing their own refresh-token call.
  Future<String?>? _refreshInFlight;

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
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint =
        _noRefreshPaths.any((p) => path.contains(p));
    final alreadyRetried = err.requestOptions.extra['kudiRetried'] == true;

    if (err.response?.statusCode != 401 || isAuthEndpoint || alreadyRetried) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      await _storage.clearAuth();
      SessionEvents.instance.notifySessionExpired();
      handler.next(err);
      return;
    }

    try {
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      retryOptions.extra['kudiRetried'] = true;
      final retryResponse = await _refreshDio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() {
    return _refreshInFlight ??=
        _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '${ApiConfig.authBaseUrl}/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final newAccessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String?;
      if (newAccessToken == null || newAccessToken.isEmpty) return null;

      await _storage.saveAuthToken(newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(newRefreshToken);
      }

      // Persist the authoritative `data.user` the auth-service returns beside
      // the rotated token pair (UserResponse, incl. user.kyc). Merging over
      // the cached model keeps this app's local-only KYC flags (Slice 4B owns
      // the server-side kyc mapping) while adopting the server's fresher
      // identity/tier fields — so a silent refresh never resets KYC progress.
      final userJson = data?['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        final existing = await _storage.getUserModel();
        await _storage.saveUserModel(
            UserModel.fromAuthResponse(userJson, existing: existing));
      }
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logging Interceptor — debug builds only
// ─────────────────────────────────────────────────────────────────────────────

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[KudiDio] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[KudiDio] ← ${response.statusCode} ${response.requestOptions.uri}');
    if (response.requestOptions.path.contains('/kyc/')) {
      debugPrint('[KudiDio]   body: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[KudiDio] ✗ ${err.type} ${err.requestOptions.uri} — ${err.message}');
    handler.next(err);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DioClient — the single HTTP wrapper used by all services
// ─────────────────────────────────────────────────────────────────────────────

class DioClient {
  final Dio _dio;
  final ConnectivityChecker _connectivity;

  DioClient({
    required String baseUrl,
    required StorageService storage,
    required ConnectivityChecker connectivity,
    Dio? dio,
    Dio? refreshDio, // injectable for testing — see _AuthInterceptor
    String? authToken, // injectable for testing
  })  : _connectivity = connectivity,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            )) {
    final effectiveRefreshDio = refreshDio ??
        Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ));
    _dio.interceptors.add(_AuthInterceptor(storage, effectiveRefreshDio));
    if (kDebugMode) _dio.interceptors.add(_LogInterceptor());
  }

  // ── Connectivity guard ─────────────────────────────────────────────────────

  Future<void> _assertConnected() async {
    final ok = await _connectivity.hasInternetConnection();
    if (!ok) throw const KudiNetworkException();
  }

  // ── Public HTTP methods ────────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _assertConnected();
    try {
      return await _dio.get<T>(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _assertConnected();
    try {
      return await _dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    await _assertConnected();
    try {
      return await _dio.put<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    await _assertConnected();
    try {
      return await _dio.patch<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    await _assertConnected();
    try {
      return await _dio.delete<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Error mapping ──────────────────────────────────────────────────────────

  Exception _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const KudiTimeoutException();

      case DioExceptionType.connectionError:
        return const KudiNetworkException(
            'Connection failed. Please check your internet.');

      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final body = e.response?.data;
        final msg = (body is Map ? body['message'] ?? body['error'] : null) ??
            'An unexpected error occurred.';

        if (code == 401 || code == 403) {
          return KudiUnauthorizedException(msg as String);
        }
        if (code != null && code >= 500) {
          return KudiServerException(
              'Server error. Please try again later.', code);
        }
        return KudiApiException(msg as String, code);

      case DioExceptionType.cancel:
        return const KudiApiException('Request was cancelled.');

      default:
        return const KudiApiException('An unexpected error occurred.');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider — single shared DioClient instance
// ─────────────────────────────────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: ApiConfig.gatewayBaseUrl,
    storage: StorageService.instance,
    connectivity: ConnectivityService.instance,
  );
});
