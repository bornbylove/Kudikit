// test/forgot_passcode_screen_test.dart
//
// Drives ForgotPasscodeScreen end to end against a fake auth-service:
// identifier -> OTP -> new passcode, checking the exact requests it makes and
// that server messages reach the user. No real network.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/presentation/login/forgot_passcode_screen.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:pinput/pinput.dart';
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

  Map<String, dynamic> bodyOf(RequestOptions r) =>
      r.data is Map<String, dynamic> ? r.data : jsonDecode(r.data as String);

  /// Opens the screen from a button so the pop result can be observed.
  Future<ValueNotifier<bool?>> openScreen(WidgetTester tester,
      {String? identifier}) async {
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
          currentConnectivityProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result.value = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasscodeScreen(
                            initialIdentifier: identifier),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return result;
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(ElevatedButton, label);
    // The steps live in a SingleChildScrollView; on a short viewport the
    // button starts off-screen, exactly as on a small phone.
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await settle(tester);
  }

  Future<void> enterOtp(WidgetTester tester, String code) async {
    await tester.enterText(
      find.descendant(
          of: find.byType(Pinput), matching: find.byType(EditableText)),
      code,
    );
    await settle(tester);
  }

  void queueSendOtp() => adapter.queueJson('/auth/send-otp', 200, {
        'status': 'success',
        'data': {
          'otpReference': 'ref-1',
          'maskedIdentifier': '+234****5678',
          'expiresInSeconds': 300,
          'resendCooldownSeconds': 60,
        },
      });

  Future<void> reachPasscodeStep(WidgetTester tester) async {
    queueSendOtp();
    adapter.queueJson('/auth/verify-otp', 200, {
      'status': 'success',
      'data': {'otpReference': 'ref-1'},
    });
    await tapButton(tester, 'Send code');
    await enterOtp(tester, '123456');
  }

  testWidgets('full flow: normalized OTP request -> verify -> reset -> pops true',
      (tester) async {
    final result = await openScreen(tester, identifier: '08012345678');

    queueSendOtp();
    await tapButton(tester, 'Send code');

    final send = adapter.requests.last;
    expect(send.path, endsWith('/auth/send-otp'));
    expect(bodyOf(send), {
      'identifier': '+2348012345678', // 0801… normalized for the server
      'purpose': 'FORGOT_PASSCODE',
    });
    // Copy must not reveal whether the account exists.
    expect(find.textContaining('If an account exists'), findsOneWidget);
    expect(find.textContaining('+234****5678'), findsOneWidget);

    adapter.queueJson('/auth/verify-otp', 200, {
      'status': 'success',
      'data': {'otpReference': 'ref-1'},
    });
    await enterOtp(tester, '123456');
    expect(bodyOf(adapter.requests.last), {
      'otpReference': 'ref-1',
      'code': '123456',
      'purpose': 'FORGOT_PASSCODE',
    });
    expect(find.text('Create a new passcode'), findsOneWidget);

    // Stale local state from the old passcode must be cleared on success.
    await storage.savePasscode('204837');
    await storage.saveBiometricCredential(const BiometricCredential(
        customerId: 'c-1', identifier: '+2348012345678', passcode: '204837'));

    adapter.queueJson('/auth/forgot-passcode/reset', 200,
        {'status': 'success', 'message': 'Passcode reset successfully'});
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '284915');
    await tester.enterText(fields.at(1), '284915');
    await tapButton(tester, 'Update passcode');

    expect(bodyOf(adapter.requests.last), {
      'otpReference': 'ref-1',
      'newPasscode': '284915',
      'confirmPasscode': '284915',
    });
    expect(result.value, isTrue);
    expect(await storage.hasPasscode(), isFalse);
    expect(await storage.getBiometricCredential(), isNull);
  });

  testWidgets('a weak passcode is rejected locally, with no request made',
      (tester) async {
    await openScreen(tester, identifier: '08012345678');
    await reachPasscodeStep(tester);
    final callsBefore = adapter.requests.length;

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), '123456');
    await tapButton(tester, 'Update passcode');

    expect(find.textContaining('sequential', findRichText: true),
        findsOneWidget);
    expect(adapter.requests.length, callsBefore);
  });

  testWidgets('mismatched confirmation is rejected locally', (tester) async {
    await openScreen(tester, identifier: '08012345678');
    await reachPasscodeStep(tester);
    final callsBefore = adapter.requests.length;

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '284915');
    await tester.enterText(fields.at(1), '284916');
    await tapButton(tester, 'Update passcode');

    expect(find.text('Passcodes do not match'), findsOneWidget);
    expect(adapter.requests.length, callsBefore);
  });

  testWidgets('a wrong OTP shows the server message and stays on the code step',
      (tester) async {
    await openScreen(tester, identifier: 'a@b.com');
    queueSendOtp();
    await tapButton(tester, 'Send code');

    adapter.queueJson('/auth/verify-otp', 400, {
      'status': 'error',
      'message': 'Invalid code. 2 attempts remaining',
    });
    await enterOtp(tester, '000000');

    expect(find.text('Invalid code. 2 attempts remaining'), findsOneWidget);
    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.text('Create a new passcode'), findsNothing);

    // Leave no periodic resend-cooldown timer running.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a rate-limited OTP request shows the server message',
      (tester) async {
    await openScreen(tester, identifier: 'a@b.com');
    adapter.queueJson('/auth/send-otp', 429, {
      'status': 'error',
      'message': 'Too many OTP requests. Try again in 60 minutes.',
    });
    await tapButton(tester, 'Send code');

    expect(find.text('Too many OTP requests. Try again in 60 minutes.'),
        findsOneWidget);
    expect(find.text('Reset your passcode'), findsOneWidget);
  });
}

/// A few short pumps: enough for the fake adapter's microtask-driven
/// responses to land without running the resend-cooldown timer to zero.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
