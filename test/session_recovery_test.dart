// test/session_recovery_test.dart
//
// Covers the pieces that let a user get back into the app:
//   1. The on-device passcode hash AppLockScreen unlocks against is written
//      on EVERY successful server-side passcode check — including the 202
//      DEVICE_LINK path that previously skipped it.
//   2. The biometric login credential's lifecycle (only while biometrics are
//      on, never inherited by another account, dropped on disable).
//   3. Logout keeps what belongs to the device (fingerprint, biometric login)
//      so the next login isn't a brand-new device needing an OTP.
// No real network — see FakeHttpClientAdapter.

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
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

  const passcode = '284915';
  const phone = '08012345678';

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

  Map<String, dynamic> sessionFor(String customerId) => {
        'status': 'success',
        'data': {
          'accessToken': 'access-$customerId',
          'refreshToken': 'refresh-$customerId',
          'tokenType': 'Bearer',
          'expiresIn': 3600,
          'user': {'customerId': customerId, 'email': '$customerId@b.com'},
        },
      };

  Map<String, dynamic> deviceChallenge() => {
        'status': 'success',
        'data': {
          'deviceVerificationRequired': true,
          'otpReference': 'otp-ref-202',
          'maskedIdentifier': 'u***8@gmail.com',
          'expiresInSeconds': 300,
        },
      };

  group('local passcode hash (what AppLockScreen unlocks against)', () {
    test('is saved on the 202 DEVICE_LINK path, where completeSession later '
        'runs without the passcode', () async {
      adapter.queueJson('/auth/login', 202, deviceChallenge());
      final notifier = AuthNotifier(authService, storage);

      await notifier.login(email: phone, password: passcode);

      expect(notifier.state.requiresDeviceVerification, isTrue);
      expect(await storage.verifyPasscode(passcode), isTrue);
      expect(await storage.verifyPasscode('204837'), isFalse);
      notifier.dispose();
    });

    test('is saved on a normal 200 login too', () async {
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      final notifier = AuthNotifier(authService, storage);

      await notifier.login(email: phone, password: passcode);

      expect(await storage.verifyPasscode(passcode), isTrue);
      notifier.dispose();
    });

    test('a rejected login saves nothing', () async {
      adapter.queue(
        '/auth/login',
        (_) => FakeHttpClientAdapter.jsonResponse(401, {
          'status': 'error',
          'message': 'Incorrect phone/email or passcode',
        }),
      );
      final notifier = AuthNotifier(authService, storage);

      await expectLater(
        notifier.login(email: phone, password: passcode),
        throwsA(isA<KudiApiException>()),
      );

      expect(await storage.hasPasscode(), isFalse);
      notifier.dispose();
    });
  });

  group('biometric login credential', () {
    test('is NOT stored while biometrics are off', () async {
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      final notifier = AuthNotifier(authService, storage);

      await notifier.login(email: phone, password: passcode);

      expect(await storage.getBiometricCredential(), isNull);
      notifier.dispose();
    });

    test('is stored after a login once biometrics are on, with the identifier '
        'in the server\'s +234 form', () async {
      await storage.setBiometricEnabled(true);
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      final notifier = AuthNotifier(authService, storage);

      await notifier.login(email: phone, password: passcode);

      final credential = await storage.getBiometricCredential();
      expect(credential, isNotNull);
      expect(credential!.customerId, 'c-1');
      expect(credential.identifier, '+2348012345678');
      expect(credential.passcode, passcode);
      notifier.dispose();
    });

    test('the same account refreshes its stored passcode', () async {
      await storage.setBiometricEnabled(true);
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      final notifier = AuthNotifier(authService, storage);
      await notifier.login(email: phone, password: '204837');

      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      await notifier.login(email: phone, password: passcode);

      expect((await storage.getBiometricCredential())!.passcode, passcode);
      expect(await storage.isBiometricEnabled(), isTrue);
      notifier.dispose();
    });

    test('a different account never inherits it: biometrics switch off and '
        'the credential is removed', () async {
      await storage.setBiometricEnabled(true);
      await storage.saveBiometricCredential(const BiometricCredential(
        customerId: 'c-1',
        identifier: '+2348012345678',
        passcode: '204837',
      ));
      adapter.queueJson('/auth/login', 200, sessionFor('c-2'));
      final notifier = AuthNotifier(authService, storage);

      await notifier.login(email: 'c-2@b.com', password: passcode);

      expect(await storage.isBiometricEnabled(), isFalse);
      expect(await storage.getBiometricCredential(), isNull);
      // The login itself still succeeded.
      expect(notifier.state.isAuthenticated, isTrue);
      notifier.dispose();
    });

    test('rememberBiometricCredential is a no-op without a live session',
        () async {
      await storage.setBiometricEnabled(true);
      final notifier = AuthNotifier(authService, storage);
      // Let the constructor's startup session check finish before disposing.
      await pumpEventQueue();

      await notifier.rememberBiometricCredential(
          identifier: phone, passcode: passcode);

      expect(notifier.state.isAuthenticated, isFalse);
      expect(await storage.getBiometricCredential(), isNull);
      notifier.dispose();
    });

    test('backfills when biometrics were enabled after the last login '
        '(the AppLockScreen unlock path)', () async {
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      final notifier = AuthNotifier(authService, storage);
      await notifier.login(email: phone, password: passcode);
      expect(await storage.getBiometricCredential(), isNull);

      await storage.setBiometricEnabled(true); // user turns it on afterwards
      await notifier.rememberBiometricCredential(
          identifier: 'c-1@b.com', passcode: passcode);

      final credential = await storage.getBiometricCredential();
      expect(credential!.customerId, 'c-1');
      expect(credential.identifier, 'c-1@b.com');
      notifier.dispose();
    });

    test('survives a JSON round-trip and can be deleted', () async {
      await storage.saveBiometricCredential(const BiometricCredential(
        customerId: 'c-9',
        identifier: 'x@y.com',
        passcode: passcode,
      ));
      final read = await storage.getBiometricCredential();
      expect(read!.customerId, 'c-9');
      expect(read.identifier, 'x@y.com');
      expect(read.passcode, passcode);

      await storage.deleteBiometricCredential();
      expect(await storage.getBiometricCredential(), isNull);
    });
  });

  group('logout', () {
    test('keeps the device fingerprint so the next login is not a new device',
        () async {
      final before = await storage.getOrCreateDeviceFingerprint();
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      adapter.queueJson('/auth/logout', 200, {'status': 'success'});
      final notifier = AuthNotifier(authService, storage);
      await notifier.login(email: phone, password: passcode);

      await notifier.logout();

      expect(await storage.getOrCreateDeviceFingerprint(), before);

      // ...and the next login presents that same fingerprint to the server.
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      await notifier.login(email: phone, password: passcode);
      final sent = adapter.requests.last.data as Map;
      expect(sent['deviceFingerprint'], before);
      notifier.dispose();
    });

    test('still clears the session: tokens, cached user, local passcode hash',
        () async {
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      adapter.queueJson('/auth/logout', 200, {'status': 'success'});
      final notifier = AuthNotifier(authService, storage);
      await notifier.login(email: phone, password: passcode);
      expect(await storage.getAuthToken(), isNotNull);

      await notifier.logout();

      expect(notifier.state.isAuthenticated, isFalse);
      expect(await storage.getAuthToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUserModel(), isNull);
      expect(await storage.hasPasscode(), isFalse);
      notifier.dispose();
    });

    test('keeps biometric login (flag + credential) for the next visit',
        () async {
      await storage.setBiometricEnabled(true);
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      adapter.queueJson('/auth/logout', 200, {'status': 'success'});
      final notifier = AuthNotifier(authService, storage);
      await notifier.login(email: phone, password: passcode);

      await notifier.logout();

      expect(await storage.isBiometricEnabled(), isTrue);
      expect((await storage.getBiometricCredential())!.customerId, 'c-1');
      notifier.dispose();
    });

    test('biometrics on but never captured a credential: switched off, so the '
        'next account does not silently enrol', () async {
      adapter.queueJson('/auth/login', 200, sessionFor('c-1'));
      adapter.queueJson('/auth/logout', 200, {'status': 'success'});
      final notifier = AuthNotifier(authService, storage);
      await notifier.login(email: phone, password: passcode);
      await storage.setBiometricEnabled(true); // enabled after login, no backfill

      await notifier.logout();

      expect(await storage.isBiometricEnabled(), isFalse);
      notifier.dispose();
    });

    test('clearSessionKeepingDevice still wipes unrelated stored data',
        () async {
      await storage.saveCurrentTier('pro');
      await storage.setBiometricEnabled(true);

      await storage.clearSessionKeepingDevice();

      expect(await storage.getCurrentTier(), 'basic'); // back to the default
      expect(await storage.isBiometricEnabled(), isTrue);
    });
  });
}
