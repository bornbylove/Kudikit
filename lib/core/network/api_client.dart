// lib/core/network/api_client.dart
// ─────────────────────────────────────────────────────────────────────────────
// Single, authoritative HTTP client for KudiPay.
//
// Moved here from lib/config/dio_client.dart during the core/ migration.
// The interceptors now live in core/network/dio_interceptor.dart.
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
import 'package:kudipay/core/network/app_exception_handler.dart';
import 'package:kudipay/core/network/dio_interceptor.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/services/storage_services.dart';

// Re-export kBaseUrl so callers that imported it from here still work.
export 'package:kudipay/core/config/network_config.dart' show kBaseUrl;
// Re-export the canonical exceptions so existing `import api_client.dart`
// call-sites continue to compile without adding a second import.
export 'package:kudipay/core/network/app_exception_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DioClient — the single HTTP wrapper used by all services
// ─────────────────────────────────────────────────────────────────────────────

class DioClient {
  final Dio _dio;
  final ConnectivityService _connectivity;

  DioClient({
    required String baseUrl,
    required StorageService storage,
    required ConnectivityService connectivity,
    Dio? dio,
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
    _dio.interceptors.add(AuthInterceptor(storage));
    if (kDebugMode) _dio.interceptors.add(KudiLogInterceptor());
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
        final msg = (body is Map ? body['message'] ?? body['error'] : null)
                ?.toString() ??
            'An unexpected error occurred.';

        if (code == 401 || code == 403) {
          return KudiUnauthorizedException(msg);
        }
        if (code != null && code >= 500) {
          return KudiServerException(
              'Server error. Please try again later.', code);
        }
        return KudiApiException(msg, code);

      case DioExceptionType.cancel:
        return const KudiApiException('Request was cancelled.');

      default:
        return const KudiApiException('An unexpected error occurred.');
    }
  }
}
