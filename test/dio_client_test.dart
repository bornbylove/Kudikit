// test/dio_client_test.dart
//
// Deterministic tests for DioClient's auth interceptor: token attachment,
// refresh-on-401 with retry, single-flight refresh, refresh-failure
// clearing the session, and no infinite refresh loop on an already-retried
// request. No real network calls — see FakeHttpClientAdapter.

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/services/session_events.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_http_client_adapter.dart';

class _AlwaysOnline implements ConnectivityChecker {
  @override
  Future<bool> hasInternetConnection() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> secureBackingStore;

  setUpAll(() {
    secureBackingStore = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureChannel, (MethodCall call) async {
      switch (call.method) {
        case 'write':
          final args = call.arguments as Map;
          secureBackingStore[args['key'] as String] = args['value'] as String;
          return null;
        case 'read':
          final args = call.arguments as Map;
          return secureBackingStore[args['key'] as String];
        case 'delete':
          final args = call.arguments as Map;
          secureBackingStore.remove(args['key'] as String);
          return null;
        case 'deleteAll':
          secureBackingStore.clear();
          return null;
        case 'readAll':
          return secureBackingStore;
        case 'containsKey':
          final args = call.arguments as Map;
          return secureBackingStore.containsKey(args['key'] as String);
        default:
          return null;
      }
    });
  });

  late StorageService storage;
  late FakeHttpClientAdapter mainAdapter;
  late FakeHttpClientAdapter refreshAdapter;
  late DioClient client;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    secureBackingStore.clear();
    storage = StorageService.instance;

    mainAdapter = FakeHttpClientAdapter();
    refreshAdapter = FakeHttpClientAdapter();

    final mainDio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = mainAdapter;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = refreshAdapter;

    client = DioClient(
      baseUrl: 'https://api.test/api/v1',
      storage: storage,
      connectivity: _AlwaysOnline(),
      dio: mainDio,
      refreshDio: refreshDio,
    );
  });

  group('Bearer token attachment', () {
    test('attaches the stored access token to outgoing requests', () async {
      await storage.saveAuthToken('access-1');
      mainAdapter.queueJson('/wallet', 200, {'status': 'success', 'data': {}});

      await client.get('/wallet');

      expect(mainAdapter.requests, hasLength(1));
      expect(mainAdapter.requests.first.headers['Authorization'],
          'Bearer access-1');
    });

    test('sends no Authorization header when no token is stored', () async {
      mainAdapter.queueJson('/wallet', 200, {'status': 'success', 'data': {}});

      await client.get('/wallet');

      expect(mainAdapter.requests.first.headers['Authorization'], isNull);
    });
  });

  group('Refresh-on-401', () {
    test('a 401 triggers refresh then retries the original request', () async {
      await storage.saveAuthToken('expired-access');
      await storage.saveRefreshToken('valid-refresh');

      mainAdapter.queueJson('/wallet', 401, {'status': 'error', 'message': 'expired'});
      refreshAdapter.queueJson('/auth/refresh-token', 200, {
        'status': 'success',
        'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
      });
      // The retry of the original request goes through refreshDio.fetch().
      refreshAdapter.queueJson('/wallet', 200, {
        'status': 'success',
        'data': {'balance': 5000},
      });

      final response = await client.get<Map<String, dynamic>>('/wallet');

      expect(response.data?['data']['balance'], 5000);
      expect(await storage.getAuthToken(), 'new-access');
      expect(await storage.getRefreshToken(), 'new-refresh');

      // The retried request must carry the NEW token, not the expired one.
      final retriedRequest = refreshAdapter.requests
          .firstWhere((r) => r.path.contains('/wallet'));
      expect(retriedRequest.headers['Authorization'], 'Bearer new-access');
    });

    test('does not attempt refresh for a 401 from the login endpoint itself',
        () async {
      mainAdapter.queueJson(
          '/auth/login', 401, {'status': 'error', 'message': 'bad creds'});

      await expectLater(
        client.post('/auth/login', data: {'identifier': 'x', 'passcode': 'y'}),
        throwsA(isA<KudiUnauthorizedException>()),
      );

      // No refresh call should ever have been attempted.
      expect(refreshAdapter.requests, isEmpty);
    });

    test('refresh failure clears the session and emits a session-expired event',
        () async {
      await storage.saveAuthToken('expired-access');
      await storage.saveRefreshToken('bad-refresh');

      mainAdapter.queueJson('/wallet', 401, {'status': 'error', 'message': 'expired'});
      refreshAdapter.queueJson('/auth/refresh-token', 401,
          {'status': 'error', 'message': 'refresh token invalid'});

      final events = <void>[];
      final sub = SessionEvents.instance.onSessionExpired.listen(events.add);

      await expectLater(
        client.get('/wallet'),
        throwsA(isA<KudiUnauthorizedException>()),
      );

      // Give the broadcast stream a turn to deliver the event.
      await Future<void>.delayed(Duration.zero);

      expect(await storage.getAuthToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(events, hasLength(1));

      await sub.cancel();
    });

    test('does not retry a request that has already been retried once',
        () async {
      await storage.saveAuthToken('expired-access');
      await storage.saveRefreshToken('valid-refresh');

      // Original request 401s.
      mainAdapter.queueJson('/wallet', 401, {'status': 'error', 'message': 'expired'});
      // Refresh succeeds.
      refreshAdapter.queueJson('/auth/refresh-token', 200, {
        'status': 'success',
        'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
      });
      // But the retried request 401s AGAIN (e.g. token immediately revoked
      // server-side) — this must NOT trigger a second refresh attempt.
      refreshAdapter.queueJson(
          '/wallet', 401, {'status': 'error', 'message': 'still expired'});

      await expectLater(
        client.get('/wallet'),
        throwsA(isA<KudiUnauthorizedException>()),
      );

      // Exactly one refresh-token call, not two.
      final refreshCalls = refreshAdapter.requests
          .where((r) => r.path.contains('/auth/refresh-token'));
      expect(refreshCalls, hasLength(1));
    });

    test('concurrent 401s share a single in-flight refresh call', () async {
      await storage.saveAuthToken('expired-access');
      await storage.saveRefreshToken('valid-refresh');

      mainAdapter.queueJson('/wallet', 401, {'status': 'error', 'message': 'expired'});
      mainAdapter.queueJson(
          '/transactions', 401, {'status': 'error', 'message': 'expired'});

      // Only one refresh response queued — if the interceptor fired two
      // refresh calls, the second would hit the "no response queued" error.
      refreshAdapter.queueJson('/auth/refresh-token', 200, {
        'status': 'success',
        'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
      });
      refreshAdapter.queueJson('/wallet', 200, {'status': 'success', 'data': {}});
      refreshAdapter.queueJson(
          '/transactions', 200, {'status': 'success', 'data': {}});

      await Future.wait([
        client.get('/wallet'),
        client.get('/transactions'),
      ]);

      final refreshCalls = refreshAdapter.requests
          .where((r) => r.path.contains('/auth/refresh-token'));
      expect(refreshCalls, hasLength(1));
    });

    test('with no stored refresh token, a 401 clears session without calling refresh',
        () async {
      await storage.saveAuthToken('expired-access');
      // No refresh token saved.

      mainAdapter.queueJson('/wallet', 401, {'status': 'error', 'message': 'expired'});

      await expectLater(
        client.get('/wallet'),
        throwsA(isA<KudiUnauthorizedException>()),
      );

      expect(refreshAdapter.requests, isEmpty);
      expect(await storage.getAuthToken(), isNull);
    });
  });
}
