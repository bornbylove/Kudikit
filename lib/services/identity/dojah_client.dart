// lib/services/identity/dojah_client.dart
//
// Dedicated HTTP client for Dojah's ML API. Deliberately NOT built on the
// shared DioClient (lib/config/dio_client.dart) — that client's interceptor
// attaches the user's Kudikit Bearer token to every request, which must
// never be sent to a third party, and Dojah's own auth scheme (a raw
// `Authorization: <secret>` header, no "Bearer" prefix, plus a separate
// `AppId` header) doesn't fit that interceptor's shape anyway. Isolating the
// Dio instance also means nothing here can accidentally pick up Kudikit's
// request/response logging.
//
// No logging interceptor is attached, on purpose: request bodies are
// base64-encoded selfies and responses carry biometric attributes, and the
// integration spec explicitly forbids logging either in production.
//
// No automatic retry on 429 — matches DioClient's existing strategy (no
// generic auto-retry beyond its own 401-refresh special case). Rate-limit
// recovery is left to the user re-tapping "Try Again" in the UI.

import 'package:dio/dio.dart';

import 'package:kudipay/config/api_config.dart';
import 'package:kudipay/config/dio_client.dart' show ConnectivityChecker;
import 'package:kudipay/model/identity/liveness_response.dart';
import 'package:kudipay/services/identity/dojah_exceptions.dart';

class DojahClient {
  final Dio _dio;
  final ConnectivityChecker? _connectivity;

  // Only the production path (no `dio` injected) needs the app-id/secret-key
  // guard — a test supplying its own Dio has already decided what headers
  // matter and shouldn't be blocked by ApiConfig's (deliberately empty by
  // default) --dart-define values.
  final bool _requiresDojahConfig;

  DojahClient({Dio? dio, ConnectivityChecker? connectivity})
      : _connectivity = connectivity,
        _requiresDojahConfig = dio == null,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.dojahBaseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': ApiConfig.dojahSecretKey,
                'AppId': ApiConfig.dojahAppId,
              },
            ));

  /// POSTs `{ "image": base64Image }` to /api/v1/ml/liveness and returns the
  /// parsed result. [base64Image] must already be a raw base64 string with
  /// no `data:image/...;base64,` prefix — callers should have produced it
  /// via ImageBase64Util.
  Future<LivenessResponse> checkLiveness(String base64Image) async {
    if (_requiresDojahConfig && !ApiConfig.isDojahConfigured) {
      throw const DojahNotConfiguredException();
    }

    if (_connectivity != null && !await _connectivity.hasInternetConnection()) {
      throw const DojahNetworkException();
    }

    late final Response response;
    try {
      response = await _dio.post(
        '/api/v1/ml/liveness',
        data: {'image': base64Image},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }

    final data = response.data;
    if (data is! Map<String, dynamic> || data['entity'] == null) {
      throw const DojahMalformedResponseException();
    }

    try {
      return LivenessResponse.fromJson(data);
    } catch (_) {
      throw const DojahMalformedResponseException();
    }
  }

  DojahException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const DojahTimeoutException();

      case DioExceptionType.connectionError:
        return const DojahNetworkException();

      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 400:
            return const DojahInvalidImageException();
          case 401:
          case 403:
            return const DojahUnauthorizedException();
          case 402:
            return const DojahInsufficientBalanceException();
          case 429:
            return const DojahRateLimitedException();
          default:
            final code = e.response?.statusCode;
            if (code != null && code >= 500) {
              return const DojahServerException();
            }
            return const DojahUnknownException();
        }

      case DioExceptionType.cancel:
        return const DojahUnknownException();

      default:
        return const DojahUnknownException();
    }
  }
}
