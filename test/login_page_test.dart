// test/login_page_test.dart
//
// LoginPage behaviour that has to be right for a user to get back in:
//   * a wrong passcode shows the PRD wording the server sent (AC 3a)
//   * biometric login is offered only when it can work, replays the stored
//     credential through the normal login, and never keeps replaying one the
//     server has rejected (every failed attempt counts toward the lockout).
// The successful-login navigation (KycFlowManager) is out of scope here, so
// every server reply in these tests is a rejection.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/biometric_service.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_http_client_adapter.dart';

class _AlwaysOnline implements ConnectivityChecker {
  @override
  Future<bool> hasInternetConnection() async => true;
}

/// Always-online stand-in for the platform-backed singleton.
class _FakeConnectivityService implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get connectionChange => _controller.stream;
  @override
  bool get hasConnection => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasInternetConnection() async => true;
  @override
  Future<List<ConnectivityResult>> getConnectivityType() async =>
      [ConnectivityResult.wifi];
  @override
  void dispose() {}
}

class _FakeBiometrics extends BiometricService {
  BiometricAvailability availability = BiometricAvailability.available;
  bool cancel = false;
  int prompts = 0;

  @override
  Future<BiometricAvailability> checkAvailability() async => availability;

  @override
  Future<bool> authenticate({required String reason}) async {
    prompts++;
    if (cancel) {
      throw const BiometricAuthException('Authentication cancelled.',
          userCancelled: true);
    }
    return true;
  }
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
  late _FakeBiometrics biometrics;

  const stored = BiometricCredential(
    customerId: 'c-1',
    identifier: '+2348012345678',
    passcode: '284915',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureBackingStore.clear();
    storage = StorageService.instance;
    biometrics = _FakeBiometrics();

    adapter = FakeHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://gateway.test/api/v1'))
      ..httpClientAdapter = adapter;
    authService = AuthService(
      storage,
      DioClient(
        baseUrl: 'https://gateway.test/api/v1',
        storage: storage,
        connectivity: _AlwaysOnline(),
        dio: dio,
        refreshDio: dio,
      ),
    );
  });

  Future<void> pumpLogin(WidgetTester tester,
      {bool autoPrompt = true, String? phone}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    // The pre-existing sign-up row overflows under the test font (Ahem is far
    // wider than the real one, and the app scales fonts with the viewport, so
    // no viewport size avoids it). Layout isn't what these tests are about;
    // every other error still fails the test.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider
              .overrideWithValue(_FakeConnectivityService()),
          authServiceProvider.overrideWithValue(authService),
          biometricServiceProvider.overrideWithValue(biometrics),
        ],
        child: MaterialApp(
          home: LoginPage(
              phoneNumber: phone, autoPromptBiometric: autoPrompt),
        ),
      ),
    );
    await settle(tester);
  }

  Map<String, dynamic> bodyOf(RequestOptions r) =>
      r.data is Map<String, dynamic> ? r.data : jsonDecode(r.data as String);

  Iterable<RequestOptions> loginRequests() =>
      adapter.requests.where((r) => r.path.endsWith('/auth/login'));

  void queueRejection(String message) => adapter.queue(
        '/auth/login',
        (_) => FakeHttpClientAdapter.jsonResponse(
            401, {'status': 'error', 'message': message}),
      );

  final biometricButton = find.text('Log in with biometrics');

  group('wrong passcode wording (PRD login AC 3a)', () {
    testWidgets('shows exactly what the server sent', (tester) async {
      await pumpLogin(tester, phone: '+2348012345678');
      queueRejection('Incorrect phone/email or passcode');

      await tester.enterText(find.byType(TextField).last, '284916');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(find.text('Incorrect phone/email or passcode'), findsOneWidget);
      expect(find.textContaining('Invalid credentials'), findsNothing);
      // The prefilled +234 number went out in the server's form.
      expect(bodyOf(loginRequests().single)['identifier'], '+2348012345678');
    });

    testWidgets('an inactive account is not shown as bad credentials',
        (tester) async {
      await pumpLogin(tester, phone: '+2348012345678');
      queueRejection('Account inactive. Contact support');

      await tester.enterText(find.byType(TextField).last, '284915');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await settle(tester);

      expect(find.text('Account inactive. Contact support'), findsOneWidget);
    });

    testWidgets('the sign-in copy is "Forgot Passcode?", not "Forgot PIN"',
        (tester) async {
      await pumpLogin(tester);
      expect(find.text('Forgot Passcode?'), findsOneWidget);
      expect(find.text('Forgot PIN'), findsNothing);
    });
  });

  group('biometric login', () {
    testWidgets('is not offered without a stored credential', (tester) async {
      await storage.setBiometricEnabled(true);
      await pumpLogin(tester);

      expect(biometricButton, findsNothing);
      expect(biometrics.prompts, 0);
    });

    testWidgets('is not offered when biometrics are switched off',
        (tester) async {
      await storage.saveBiometricCredential(stored);
      await pumpLogin(tester);

      expect(biometricButton, findsNothing);
      expect(biometrics.prompts, 0);
    });

    testWidgets('is not offered when the device cannot prompt', (tester) async {
      await storage.setBiometricEnabled(true);
      await storage.saveBiometricCredential(stored);
      biometrics.availability = BiometricAvailability.notEnrolled;
      await pumpLogin(tester);

      expect(biometricButton, findsNothing);
      expect(biometrics.prompts, 0);
    });

    testWidgets('prompts on open and replays the stored credential through '
        'the normal login', (tester) async {
      await storage.setBiometricEnabled(true);
      await storage.saveBiometricCredential(stored);
      queueRejection('Incorrect phone/email or passcode');

      await pumpLogin(tester);

      expect(biometrics.prompts, 1);
      final body = bodyOf(loginRequests().single);
      expect(body['identifier'], '+2348012345678');
      expect(body['passcode'], '284915');
      expect(body['deviceFingerprint'], isNotEmpty);
    });

    testWidgets('a credential the server rejects is dropped, so it is not '
        'replayed again (each failure counts toward the lockout)',
        (tester) async {
      await storage.setBiometricEnabled(true);
      await storage.saveBiometricCredential(stored);
      queueRejection('Incorrect phone/email or passcode');

      await pumpLogin(tester);

      expect(await storage.getBiometricCredential(), isNull);
      // Biometrics stay enabled so the next passcode login re-captures one.
      expect(await storage.isBiometricEnabled(), isTrue);
      expect(biometricButton, findsNothing);
      expect(find.text('Incorrect phone/email or passcode'), findsOneWidget);
      expect(loginRequests().length, 1);
    });

    testWidgets('cancelling the prompt makes no login request and shows no '
        'error', (tester) async {
      await storage.setBiometricEnabled(true);
      await storage.saveBiometricCredential(stored);
      biometrics.cancel = true;

      await pumpLogin(tester);

      expect(biometrics.prompts, 1);
      expect(loginRequests(), isEmpty);
      expect(find.textContaining('cancelled'), findsNothing);
      // ...and the button is there to try again.
      expect(biometricButton, findsOneWidget);
      expect(await storage.getBiometricCredential(), isNotNull);
    });

    testWidgets('does not auto-prompt right after a deliberate sign-out, but '
        'the button still works', (tester) async {
      await storage.setBiometricEnabled(true);
      await storage.saveBiometricCredential(stored);
      queueRejection('Incorrect phone/email or passcode');

      await pumpLogin(tester, autoPrompt: false);

      expect(biometrics.prompts, 0);
      expect(loginRequests(), isEmpty);
      expect(biometricButton, findsOneWidget);

      await tester.tap(biometricButton);
      await settle(tester);

      expect(biometrics.prompts, 1);
      expect(loginRequests().length, 1);
    });
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
