// test/app_lock_screen_test.dart
//
// AppLockScreen is drawn ABOVE the Navigator (MaterialApp.builder), which is
// what makes its escape hatch non-obvious: it must sign out, then reach
// LoginPage through the root navigator key. Also covers unlocking with the
// on-device passcode hash and the biometric-credential backfill that happens
// on a correct passcode.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/navigation/root_navigator.dart';
import 'package:kudipay/presentation/lock/app_lock_screen.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/auth/biometric_provider.dart';
import 'package:kudipay/provider/auth/session_lock_provider.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/biometric_service.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/services/security_services.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_http_client_adapter.dart';

class _AlwaysOnline implements ConnectivityChecker {
  @override
  Future<bool> hasInternetConnection() async => true;
}

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

class _NoBiometrics extends BiometricService {
  @override
  Future<BiometricAvailability> checkAvailability() async =>
      BiometricAvailability.unsupported;
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
  late SecurityService securityService;
  late ProviderContainer container;

  const passcode = '284915';

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
    securityService = SecurityService(client);
  });

  /// Logs in (so there is a live session and a local passcode hash) and shows
  /// the lock screen over a stand-in app screen.
  Future<void> pumpLocked(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    adapter.queueJson('/auth/login', 200, {
      'status': 'success',
      'data': {
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'user': {'customerId': 'c-1', 'email': 'a@b.com'},
      },
    });

    container = ProviderContainer(overrides: [
      connectivityServiceProvider
          .overrideWithValue(_FakeConnectivityService()),
      authServiceProvider.overrideWithValue(authService),
      biometricServiceProvider.overrideWithValue(_NoBiometrics()),
      securityServiceProvider.overrideWithValue(securityService),
    ]);
    addTearDown(container.dispose);
    // Real async (Dio + secure storage): FakeAsync alone never completes it.
    await tester.runAsync(() => container
        .read(authProvider.notifier)
        .login(email: 'a@b.com', password: passcode));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          // Same shape as main.dart: the lock screen sits above the Navigator.
          builder: (context, child) => Stack(children: [
            if (child != null) child,
            const AppLockScreen(),
          ]),
          home: const Scaffold(body: Center(child: Text('underlying app'))),
        ),
      ),
    );
    await settle(tester);
  }

  /// Arms the idle timer and locks — what splashscreen.dart does on a cold
  /// start with a cached session. arm() also asks /security/settings for the
  /// timeout; that is answered 404 here so it falls back to the tier default.
  Future<void> armAndLock() async {
    adapter.queueJson('/security/settings', 404, {'status': 'error'});
    final notifier = container.read(sessionLockProvider.notifier);
    await notifier.arm();
    notifier.lockNow();
  }

  Future<void> typePasscode(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).first);
      await tester.pump();
    }
    await settle(tester);
  }

  testWidgets('a correct passcode unlocks (checked against the local hash)',
      (tester) async {
    await pumpLocked(tester);
    await armAndLock();
    expect(container.read(sessionLockProvider).phase, SessionLockPhase.locked);

    await typePasscode(tester, passcode);
    await tester.tap(find.text('Unlock'));
    await settle(tester);

    expect(
        container.read(sessionLockProvider).phase, SessionLockPhase.unlocked);
    container.read(sessionLockProvider.notifier).disarm();
  });

  testWidgets('a wrong passcode is rejected and stays locked', (tester) async {
    await pumpLocked(tester);
    await armAndLock();

    await typePasscode(tester, '204837');
    await tester.tap(find.text('Unlock'));
    await settle(tester);

    expect(find.text('Incorrect passcode'), findsOneWidget);
    expect(container.read(sessionLockProvider).phase, SessionLockPhase.locked);
    container.read(sessionLockProvider.notifier).disarm();
  });

  testWidgets('a correct passcode backfills the biometric credential when '
      'biometrics were switched on after login', (tester) async {
    await pumpLocked(tester);
    await armAndLock();
    await storage.setBiometricEnabled(true);
    expect(await storage.getBiometricCredential(), isNull);

    await typePasscode(tester, passcode);
    await tester.tap(find.text('Unlock'));
    await settle(tester);

    final credential = await storage.getBiometricCredential();
    expect(credential, isNotNull);
    expect(credential!.customerId, 'c-1');
    expect(credential.identifier, 'a@b.com');
    expect(credential.passcode, passcode);
    container.read(sessionLockProvider.notifier).disarm();
  });

  testWidgets('Forgot passcode? -> confirm -> Sign out logs out and lands on '
      'the login page', (tester) async {
    await pumpLocked(tester);
    await armAndLock();
    adapter.queueJson('/auth/logout', 200, {'status': 'success'});

    await tester.tap(find.text('Forgot passcode?'));
    await tester.pump();
    // Inline confirmation (a dialog would open beneath this overlay).
    expect(find.textContaining('signed out on this device'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await settle(tester);

    expect(container.read(authProvider).isAuthenticated, isFalse);
    expect(adapter.requests.any((r) => r.path.endsWith('/auth/logout')), isTrue);
    expect(await storage.getAuthToken(), isNull);
    expect(container.read(sessionLockProvider).phase,
        SessionLockPhase.unlocked); // disarmed: the overlay is gone
    // The Navigator now shows LoginPage.
    expect(find.byType(LoginPage), findsOneWidget);
    expect(
        tester.widget<LoginPage>(find.byType(LoginPage)).autoPromptBiometric,
        isFalse);
  });

  testWidgets('Cancel on the confirmation keeps the user signed in',
      (tester) async {
    await pumpLocked(tester);
    await armAndLock();

    await tester.tap(find.text('Forgot passcode?'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await settle(tester); // also drains arm()'s /security/settings request

    expect(find.text('Forgot passcode?'), findsOneWidget);
    expect(container.read(authProvider).isAuthenticated, isTrue);
    expect(adapter.requests.any((r) => r.path.endsWith('/auth/logout')),
        isFalse);
    container.read(sessionLockProvider.notifier).disarm();
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
