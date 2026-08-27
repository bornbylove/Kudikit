// lib/config/api_config.dart
// Single source of truth for backend base URLs.
//
// The platform is NOT one host today: kudikit_auth_service and Kudikitgateway
// are separate deployments (confirmed live at 199.192.22.72:8090 and
// presumably :8080 respectively during the 2026-08-08 architecture audit).
// `api.Kudikit.com` does not currently resolve — it's a placeholder for the
// eventual reverse-proxied production domain. Until that exists, override
// per-build with --dart-define, e.g.:
//   flutter run \
//     --dart-define=KUDIKIT_AUTH_BASE_URL=http://199.192.22.72:8090/api/v1 \
//     --dart-define=KUDIKIT_GATEWAY_BASE_URL=http://<gateway-host>:8080/api/v1
//
// kBaseUrl / ApiConfig.baseUrl are kept as aliases for ApiConfig.gatewayBaseUrl
// so the ~10 existing call sites that import kBaseUrl from mock_api_data.dart
// keep compiling unchanged.

class ApiConfig {
  ApiConfig._();

  static const String gatewayBaseUrl = String.fromEnvironment(
    'KUDIKIT_GATEWAY_BASE_URL',
    defaultValue: 'http://199.192.22.72:8090/api/v1',
  );

  static const String authBaseUrl = String.fromEnvironment(
    'KUDIKIT_AUTH_BASE_URL',
    defaultValue: 'http://199.192.22.72:8090/api/v1',
  );

  // Deprecated: use gatewayBaseUrl directly or inject DioClient via Riverpod.
  static String get baseUrl => gatewayBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}


const String kBaseUrl = ApiConfig.gatewayBaseUrl;
