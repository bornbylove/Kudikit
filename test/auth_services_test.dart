// test/auth_services_test.dart
//
// Verifies AuthService sends the exact request shapes kudikit_auth_service
// expects (per its live OpenAPI spec + RegisterRequest.java, verified
// 2026-08-08) and correctly surfaces the response envelope. No real network
// calls — see FakeHttpClientAdapter.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/services/auth_services.dart';
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
  late FakeHttpClientAdapter adapter;
  late AuthService authService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureBackingStore.clear();
    storage = StorageService.instance;

    adapter = FakeHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://gateway.test/api/v1'))
      ..httpClientAdapter = adapter;

    final client = DioClient(
      baseUrl: 'https://gateway.test/api/v1',
      storage: storage,
      connectivity: _AlwaysOnline(),
      dio: dio,
      refreshDio: dio,
    );
    authService = AuthService(storage, client);
  });

  Map<String, dynamic> lastBody(FakeHttpClientAdapter a) {
    final raw = a.requests.last.data;
    return raw is Map<String, dynamic> ? raw : jsonDecode(raw as String);
  }

  group('sendOtp', () {
    test('sends {phoneNumber, email, purpose} — not the old {channel} shape',
        () async {
      adapter.queueJson('/auth/send-otp', 200, {
        'status': 'success',
        'data': {'otpReference': 'otp-ref-1', 'expiresInSeconds': 120},
      });

      await authService.sendOtp(
        phoneNumber: '+2348012345678',
        email: 'a@b.com',
      );

      final body = lastBody(adapter);
      expect(body['phoneNumber'], '+2348012345678');
      expect(body['email'], 'a@b.com');
      expect(body['purpose'], OtpPurpose.registration);
      expect(body.containsKey('channel'), isFalse);
    });

    test('request goes to the auth host, not a doubled /api/v1/api/v1 path',
        () async {
      adapter.queueJson('/auth/send-otp', 200, {
        'status': 'success',
        'data': {'otpReference': 'otp-ref-1'},
      });

      await authService.sendOtp(phoneNumber: '+2348012345678', email: 'a@b.com');

      final uri = adapter.requests.last.uri.toString();
      expect(uri.contains('/api/v1/api/v1'), isFalse);
      expect(uri, endsWith('/api/v1/auth/send-otp'));
    });
  });

  group('verifyOtp', () {
    test('sends {otpReference, code, purpose} — not the old {otpId, otp, action}',
        () async {
      adapter.queueJson('/auth/verify-otp', 200, {
        'status': 'success',
        'data': {'otpReference': 'otp-ref-1'},
      });

      await authService.verifyOtp(otpReference: 'otp-ref-1', code: '222335');

      final body = lastBody(adapter);
      expect(body['otpReference'], 'otp-ref-1');
      expect(body['code'], '222335');
      expect(body['purpose'], OtpPurpose.registration);
      expect(body.containsKey('otpId'), isFalse);
      expect(body.containsKey('otp'), isFalse);
      expect(body.containsKey('action'), isFalse);
    });
  });

  group('register', () {
    test('sends {otpReference, phoneNumber, email, passcode, confirmPasscode} '
        'and omits fullName by default — PRD registration is phone/email/passcode only',
        () async {
      adapter.queueJson('/auth/register', 200, {
        'status': 'success',
        'data': {
          'accessToken': 'a',
          'refreshToken': 'r',
          'user': {'customerId': 'c-1'},
        },
      });

      await authService.register(
        otpReference: 'otp-ref-1',
        phoneNumber: '+2348012345678',
        email: 'a@b.com',
        passcode: '284915',
        confirmPasscode: '284915',
      );

      final body = lastBody(adapter);
      expect(body['otpReference'], 'otp-ref-1');
      expect(body['phoneNumber'], '+2348012345678');
      expect(body['email'], 'a@b.com');
      expect(body['passcode'], '284915');
      expect(body['confirmPasscode'], '284915');
      expect(body.containsKey('phone'), isFalse); // old, wrong field name
      // fullName is deliberately not part of this app's registration data —
      // see the backend advisory on RegisterRequest.fullName still being
      // @NotBlank server-side; that's a tracked backend gap, not something
      // to route around by always sending a value from mobile.
      expect(body.containsKey('fullName'), isFalse);
    });

    test('includes fullName only when explicitly supplied', () async {
      adapter.queueJson('/auth/register', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });

      await authService.register(
        otpReference: 'otp-ref-1',
        phoneNumber: '+2348012345678',
        email: 'a@b.com',
        fullName: 'Abraham Chidubem',
        passcode: '284915',
        confirmPasscode: '284915',
      );

      expect(lastBody(adapter)['fullName'], 'Abraham Chidubem');
    });

    test('omits referralCode when not supplied, includes it when supplied',
        () async {
      adapter.queueJson('/auth/register', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });
      await authService.register(
        otpReference: 'otp-ref-1',
        phoneNumber: '+2348012345678',
        email: 'a@b.com',
        fullName: 'Abraham Chidubem',
        passcode: '284915',
        confirmPasscode: '284915',
      );
      expect(lastBody(adapter).containsKey('referralCode'), isFalse);

      adapter.queueJson('/auth/register', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });
      await authService.register(
        otpReference: 'otp-ref-1',
        phoneNumber: '+2348012345678',
        email: 'a@b.com',
        fullName: 'Abraham Chidubem',
        passcode: '284915',
        confirmPasscode: '284915',
        referralCode: 'KUDI12',
      );
      expect(lastBody(adapter)['referralCode'], 'KUDI12');
    });
  });

  group('login', () {
    test('sends {identifier, passcode}', () async {
      adapter.queueJson('/auth/login', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });

      await authService.login(identifier: '+2348012345678', passcode: '284915');

      final body = lastBody(adapter);
      expect(body['identifier'], '+2348012345678');
      expect(body['passcode'], '284915');
    });

    test('maps a 401 to a friendly invalid-credentials message', () async {
      adapter.queue(
        '/auth/login',
        (_) => FakeHttpClientAdapter.jsonResponse(
            401, {'status': 'error', 'message': 'Invalid passcode'}),
      );

      await expectLater(
        authService.login(identifier: '+2348012345678', passcode: 'wrong1'),
        throwsA(isA<KudiApiException>().having(
          (e) => e.message,
          'message',
          contains('Invalid credentials'),
        )),
      );
    });
  });

  group('logout', () {
    test('sends the stored refreshToken and clears local auth regardless of outcome',
        () async {
      await storage.saveAuthToken('access-1');
      await storage.saveRefreshToken('refresh-1');
      adapter.queueJson('/auth/logout', 200, {'status': 'success', 'data': null});

      await authService.logout();

      final body = lastBody(adapter);
      expect(body['refreshToken'], 'refresh-1');
      expect(await storage.getAuthToken(), isNull);
    });

    test('still clears local auth even if the server call fails', () async {
      await storage.saveAuthToken('access-1');
      await storage.saveRefreshToken('refresh-1');
      adapter.queue(
        '/auth/logout',
        (_) => FakeHttpClientAdapter.jsonResponse(500, {'status': 'error'}),
      );

      await authService.logout();

      expect(await storage.getAuthToken(), isNull);
    });

    test('does not call the server at all when there is no refresh token',
        () async {
      await storage.saveAuthToken('access-1'); // access token but no refresh
      await authService.logout();
      expect(adapter.requests, isEmpty);
      expect(await storage.getAuthToken(), isNull);
    });
  });
}
