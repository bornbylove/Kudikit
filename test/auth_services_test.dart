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
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/profile_services.dart';
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
  late ProfileService profileService;

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
    profileService = ProfileService(client, storage);
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

    test('DEVICE_LINK (resend) sends {identifier, purpose} — no phoneNumber/email',
        () async {
      adapter.queueJson('/auth/send-otp', 200, {
        'status': 'success',
        'data': {'otpReference': 'otp-ref-1'},
      });

      await authService.sendOtp(
        identifier: '+2348012345678',
        purpose: OtpPurpose.deviceLink,
      );

      final body = lastBody(adapter);
      expect(body['identifier'], '+2348012345678');
      expect(body['purpose'], OtpPurpose.deviceLink);
      expect(body.containsKey('phoneNumber'), isFalse);
      expect(body.containsKey('email'), isFalse);
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
    test('sends {otpReference, phoneNumber, email, passcode, confirmPasscode, '
        'deviceFingerprint, deviceName} and omits fullName by default — PRD '
        'registration is phone/email/passcode only',
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
      // fullName is not part of this app's registration data, and the
      // backend RegisterRequest.java has no fullName field at all.
      expect(body.containsKey('fullName'), isFalse);
      // deviceFingerprint is optional at register but sending it trusts the
      // registering device immediately (AuthServiceImpl.register), so the
      // first login on this device skips the DEVICE_LINK challenge.
      final fp = body['deviceFingerprint'] as String?;
      expect(fp, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(body['deviceName'], isNotEmpty);
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
    test('sends {identifier, passcode, deviceFingerprint, deviceName}',
        () async {
      adapter.queueJson('/auth/login', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });

      await authService.login(
          identifier: '+2348012345678', passcode: '284915');

      final body = lastBody(adapter);
      expect(body['identifier'], '+2348012345678');
      expect(body['passcode'], '284915');
      // deviceFingerprint is @NotBlank in LoginRequest.java.
      final fp = body['deviceFingerprint'] as String?;
      expect(fp, isNotNull);
      expect(fp, isNotEmpty);
      // 16 random bytes hex-encoded → 32 chars.
      expect(fp, matches(RegExp(r'^[0-9a-f]{32}$')));
      // deviceName is optional but we always send the cheap model label.
      final dn = body['deviceName'] as String?;
      expect(dn, isNotNull);
      expect(dn, isNotEmpty);
    });

    test('reuses the same deviceFingerprint across logins (stable per install)',
        () async {
      adapter.queueJson('/auth/login', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });
      await authService.login(identifier: '+2348012345678', passcode: '284915');
      final first = lastBody(adapter)['deviceFingerprint'];

      adapter.queueJson('/auth/login', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });
      await authService.login(identifier: '+2348012345678', passcode: '284915');
      final second = lastBody(adapter)['deviceFingerprint'];

      expect(second, first);
    });

    // The strings below are exactly what AuthServiceImpl.login() returns and
    // what PRD login AC 3a/3d specify — the app must show them, not its own.
    test('a wrong passcode shows the PRD wording the server sends (AC 3a)',
        () async {
      adapter.queue(
        '/auth/login',
        (_) => FakeHttpClientAdapter.jsonResponse(401, {
          'status': 'error',
          'message': 'Incorrect phone/email or passcode',
        }),
      );

      await expectLater(
        authService.login(identifier: '+2348012345678', passcode: '284916'),
        throwsA(isA<KudiApiException>()
            .having((e) => e.message, 'message',
                'Incorrect phone/email or passcode')
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('an inactive account is not disguised as bad credentials (AC 3d)',
        () async {
      adapter.queue(
        '/auth/login',
        (_) => FakeHttpClientAdapter.jsonResponse(401, {
          'status': 'error',
          'message': 'Account inactive. Contact support',
        }),
      );

      await expectLater(
        authService.login(identifier: '+2348012345678', passcode: '284915'),
        throwsA(isA<KudiApiException>().having(
            (e) => e.message, 'message', 'Account inactive. Contact support')),
      );
    });

    test('a locked account (429) keeps its own message (AC 3b)', () async {
      adapter.queue(
        '/auth/login',
        (_) => FakeHttpClientAdapter.jsonResponse(429, {
          'status': 'error',
          'message': 'Account locked. Try again in 60 minutes.',
        }),
      );

      await expectLater(
        authService.login(identifier: '+2348012345678', passcode: '284915'),
        throwsA(isA<KudiApiException>().having((e) => e.message, 'message',
            'Account locked. Try again in 60 minutes.')),
      );
    });

    test('falls back to the PRD wording when the 401 body has no message',
        () async {
      adapter.queue(
        '/auth/login',
        (_) => FakeHttpClientAdapter.jsonResponse(401, {'status': 'error'}),
      );

      // DioClient supplies its generic text when the body has none; the auth
      // screens still must not show "Invalid credentials".
      await expectLater(
        authService.login(identifier: '+2348012345678', passcode: '284915'),
        throwsA(isA<KudiApiException>().having(
            (e) => e.message, 'message', isNot(contains('Invalid credentials')))),
      );
    });

    test('normalizes a local 0801… phone to the +234 form the server stores',
        () async {
      adapter.queueJson('/auth/login', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });

      await authService.login(identifier: '08012345678', passcode: '284915');

      expect(lastBody(adapter)['identifier'], '+2348012345678');
    });

    test('leaves an email identifier untouched', () async {
      adapter.queueJson('/auth/login', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });

      await authService.login(identifier: 'a@b.com', passcode: '284915');

      expect(lastBody(adapter)['identifier'], 'a@b.com');
    });
  });

  group('normalizeLoginIdentifier', () {
    test('handles every phone shape a user can plausibly type', () {
      expect(normalizeLoginIdentifier('08012345678'), '+2348012345678');
      expect(normalizeLoginIdentifier('0801 234 5678'), '+2348012345678');
      expect(normalizeLoginIdentifier('2348012345678'), '+2348012345678');
      expect(normalizeLoginIdentifier('+2348012345678'), '+2348012345678');
      expect(normalizeLoginIdentifier('+234 801 234 5678'), '+2348012345678');
      expect(normalizeLoginIdentifier('09012345678'), '+2349012345678');
    });

    test('does not touch emails or unrecognised input', () {
      expect(normalizeLoginIdentifier(' User@Mail.com '), 'User@Mail.com');
      expect(normalizeLoginIdentifier('12345'), '12345');
      // A landline-looking number is not a mobile number — pass through as-is
      // and let the server decide.
      expect(normalizeLoginIdentifier('01234567890'), '01234567890');
    });
  });

  group('forgot passcode', () {
    test('OTP request sends {identifier, purpose: FORGOT_PASSCODE}, normalized',
        () async {
      adapter.queueJson('/auth/send-otp', 200, {
        'status': 'success',
        'data': {'otpReference': 'ref-1', 'resendCooldownSeconds': 60},
      });

      final response = await authService.sendOtp(
        identifier: '08012345678',
        purpose: OtpPurpose.forgotPasscode,
      );

      final body = lastBody(adapter);
      expect(body['identifier'], '+2348012345678');
      expect(body['purpose'], 'FORGOT_PASSCODE');
      expect(body.containsKey('phoneNumber'), isFalse);
      expect((response['data'] as Map)['otpReference'], 'ref-1');
    });

    test('resetPasscode POSTs {otpReference, newPasscode, confirmPasscode} '
        'to /auth/forgot-passcode/reset', () async {
      adapter.queueJson('/auth/forgot-passcode/reset', 200, {
        'status': 'success',
        'message': 'Passcode reset successfully, please log in again',
      });

      await authService.resetPasscode(
        otpReference: 'ref-1',
        newPasscode: '284915',
        confirmPasscode: '284915',
      );

      final request = adapter.requests.last;
      expect(request.uri.toString(),
          endsWith('/api/v1/auth/forgot-passcode/reset'));
      final body = lastBody(adapter);
      expect(body, {
        'otpReference': 'ref-1',
        'newPasscode': '284915',
        'confirmPasscode': '284915',
      });
    });

    test('resetPasscode surfaces the server message (passcode rules, bad OTP)',
        () async {
      adapter.queueJson('/auth/forgot-passcode/reset', 400, {
        'status': 'error',
        'message': 'Passcode is too common',
      });

      await expectLater(
        authService.resetPasscode(
          otpReference: 'ref-1',
          newPasscode: '123456',
          confirmPasscode: '123456',
        ),
        throwsA(isA<KudiApiException>()
            .having((e) => e.message, 'message', 'Passcode is too common')),
      );
    });

    test('a 401 on reset does not trigger a token refresh / session wipe',
        () async {
      await storage.saveRefreshToken('live-refresh');
      adapter.queueJson('/auth/forgot-passcode/reset', 401, {
        'status': 'error',
        'message': 'OTP not verified',
      });

      await expectLater(
        authService.resetPasscode(
          otpReference: 'ref-1',
          newPasscode: '284915',
          confirmPasscode: '284915',
        ),
        throwsA(isA<KudiApiException>()),
      );

      expect(adapter.requests.any((r) => r.path.contains('refresh-token')),
          isFalse);
      expect(await storage.getRefreshToken(), 'live-refresh');
    });
  });

  group('verifyDeviceLogin', () {
    test('sends {otpReference, deviceFingerprint, deviceName} and returns the '
        'envelope', () async {
      adapter.queueJson('/auth/login/verify-device', 200, {
        'status': 'success',
        'data': {
          'accessToken': 'a',
          'refreshToken': 'r',
          'user': {'customerId': 'c-1'},
        },
      });

      final response = await authService.verifyDeviceLogin(
          otpReference: 'otp-ref-1');

      final body = lastBody(adapter);
      expect(body['otpReference'], 'otp-ref-1');
      // Same persistent fingerprint as login — no new one created.
      final fp = body['deviceFingerprint'] as String?;
      expect(fp, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(body['deviceName'], isNotEmpty);
      expect(response['data'], isNotNull);
    });

    test('endpoint is permitAll — request carries no Authorization header',
        () async {
      adapter.queueJson('/auth/login/verify-device', 200, {
        'status': 'success',
        'data': {'accessToken': 'a', 'refreshToken': 'r', 'user': {}},
      });

      await authService.verifyDeviceLogin(otpReference: 'otp-ref-1');

      final headers = adapter.requests.last.headers;
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('an inactive account keeps its message instead of being wrapped as '
        '"Device verification failed: …"', () async {
      adapter.queueJson('/auth/login/verify-device', 401, {
        'status': 'error',
        'message': 'Account inactive. Contact support',
      });

      await expectLater(
        authService.verifyDeviceLogin(otpReference: 'otp-ref-1'),
        throwsA(isA<KudiApiException>().having(
            (e) => e.message, 'message', 'Account inactive. Contact support')),
      );
    });
  });

  group('KYC submissions (Slice 5)', () {
    Map<String, dynamic> fullEntity({
      String status = 'VERIFIED',
      bool bvnVerified = true,
      bool ninVerified = false,
      bool livenessVerified = true,
      String idDocumentStatus = 'NOT_STARTED',
      String addressStatus = 'NOT_STARTED',
      bool requiresManualReview = false,
    }) {
      return {
        'id': 1,
        'status': status,
        'bvnVerified': bvnVerified,
        'ninVerified': ninVerified,
        'livenessVerified': livenessVerified,
        'bvnFullName': 'ABRAHAM CHIDUBEM',
        'bvnDateOfBirth': '1995-05-15',
        'ninFullName': null,
        'ninDateOfBirth': null,
        'idDocumentStatus': idDocumentStatus,
        'addressStatus': addressStatus,
        'requiresManualReview': requiresManualReview,
        'bvnHash': 'hash-abc',
      };
    }

    test('verifyBvn POSTs {bvn, selfieImageBase64} to /auth/kyc/verify-bvn and '
        'maps the entity into KycStatusSummary incl. identity details', () async {
      adapter.queueJson('/auth/kyc/verify-bvn', 200, {
        'status': 'success',
        'message': 'BVN verified successfully',
        'data': fullEntity(),
      });

      final summary = await authService.verifyBvn(
        bvn: '12345678901',
        selfieImageBase64: 'aGVsbG8=',
      );

      final body = lastBody(adapter);
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.path, contains('/auth/kyc/verify-bvn'));
      expect(body['bvn'], '12345678901');
      expect(body['selfieImageBase64'], 'aGVsbG8=');

      expect(summary.status, KycStatus.verified);
      expect(summary.bvnVerified, isTrue);
      expect(summary.livenessVerified, isTrue);
      expect(summary.fullName, 'ABRAHAM CHIDUBEM');
      expect(summary.dateOfBirth, '1995-05-15');
    });

    test('verifyNin POSTs {nin, selfieImageBase64} to /auth/kyc/verify-nin',
        () async {
      adapter.queueJson('/auth/kyc/verify-nin', 200, {
        'status': 'success',
        'message': 'NIN verified successfully',
        'data': fullEntity(
          status: 'VERIFIED',
          bvnVerified: true,
          ninVerified: true,
          livenessVerified: true,
        ),
      });

      final summary = await authService.verifyNin(
        nin: '12345678901',
        selfieImageBase64: 'aGVsbG8=',
      );

      final body = lastBody(adapter);
      expect(adapter.requests.last.path, contains('/auth/kyc/verify-nin'));
      expect(body['nin'], '12345678901');
      expect(body.containsKey('bvn'), isFalse);
      expect(body['selfieImageBase64'], 'aGVsbG8=');
      expect(summary.ninVerified, isTrue);
      expect(summary.fullName, 'ABRAHAM CHIDUBEM');
      expect(summary.dateOfBirth, '1995-05-15');
    });

    test('verifyIdDocument sends documentType, front and back base64',
        () async {
      adapter.queueJson('/auth/kyc/verify-id-document', 200, {
        'status': 'success',
        'message': 'Document verified',
        'data': fullEntity(idDocumentStatus: 'VERIFIED'),
      });

      final summary = await authService.verifyIdDocument(
        documentType: 'NATIONAL_ID',
        frontImageBase64: 'ZnJvbnQ=',
        backImageBase64: 'YmFjaw==',
      );

      final body = lastBody(adapter);
      expect(adapter.requests.last.path,
          contains('/auth/kyc/verify-id-document'));
      expect(body['documentType'], 'NATIONAL_ID');
      expect(body['frontImageBase64'], 'ZnJvbnQ=');
      expect(body['backImageBase64'], 'YmFjaw==');
      expect(summary.idDocumentStatus, IdDocumentStatus.verified);
    });

    test('verifyIdDocument omits backImageBase64 for passport', () async {
      adapter.queueJson('/auth/kyc/verify-id-document', 200, {
        'status': 'success',
        'data': fullEntity(idDocumentStatus: 'VERIFIED'),
      });

      await authService.verifyIdDocument(
        documentType: 'PASSPORT',
        frontImageBase64: 'ZnJvbnQ=',
      );

      final body = lastBody(adapter);
      expect(body.containsKey('backImageBase64'), isFalse);
    });

    test('verifyIdDocument maps a 200 MANUAL_REVIEW into the typed state '
        '(200 is NOT treated as VERIFIED)', () async {
      adapter.queueJson('/auth/kyc/verify-id-document', 200, {
        'status': 'success',
        'message': 'Document under review',
        'data': fullEntity(
          status: 'MANUAL_REVIEW',
          idDocumentStatus: 'MANUAL_REVIEW',
          requiresManualReview: true,
        ),
      });

      final summary = await authService.verifyIdDocument(
        documentType: 'DRIVERS_LICENSE',
        frontImageBase64: 'ZnJvbnQ=',
        backImageBase64: 'YmFjaw==',
      );

      expect(summary.idDocumentStatus, IdDocumentStatus.manualReview);
      expect(summary.requiresManualReview, isTrue);
      expect(summary.status, KycStatus.manualReview);
    });

    test('verifyAddress sends the full mapped address payload', () async {
      adapter.queueJson('/auth/kyc/verify-address', 200, {
        'status': 'success',
        'message': 'Address submitted for agent verification',
        'data': fullEntity(
          status: 'IN_PROGRESS',
          addressStatus: 'PENDING_AGENT_VISIT',
        ),
      });

      final summary = await authService.verifyAddress(
        houseNumber: '12',
        street: 'Broad Street',
        landmark: 'Near the market',
        area: 'Lekki Phase 1',
        lga: 'Eti-Osa',
        city: 'Lagos',
        state: 'Lagos',
        utilityBillImageBase64: 'YmlsbA==',
      );

      final body = lastBody(adapter);
      expect(adapter.requests.last.path, contains('/auth/kyc/verify-address'));
      expect(body['houseNumber'], '12');
      expect(body['street'], 'Broad Street');
      expect(body['landmark'], 'Near the market');
      expect(body['area'], 'Lekki Phase 1');
      expect(body['lga'], 'Eti-Osa');
      expect(body['city'], 'Lagos');
      expect(body['state'], 'Lagos');
      expect(body['utilityBillImageBase64'], 'YmlsbA==');
      expect(summary.addressStatus, AddressVerificationStatus.pendingAgentVisit);
      expect(summary.status, KycStatus.inProgress);
    });

    test('verifyAddress omits optional landmark and area when empty', () async {
      adapter.queueJson('/auth/kyc/verify-address', 200, {
        'status': 'success',
        'data': fullEntity(addressStatus: 'PENDING_AGENT_VISIT'),
      });

      await authService.verifyAddress(
        houseNumber: '12',
        street: 'Broad Street',
        lga: 'Eti-Osa',
        city: 'Lagos',
        state: 'Lagos',
        utilityBillImageBase64: 'YmlsbA==',
      );

      final body = lastBody(adapter);
      expect(body.containsKey('landmark'), isFalse);
      expect(body.containsKey('area'), isFalse);
    });

    test('a 400 rejection surfaces the server message via KudiApiException',
        () async {
      adapter.queue(
        '/auth/kyc/verify-bvn',
        (_) => FakeHttpClientAdapter.jsonResponse(400, {
          'status': 'error',
          'message': 'Selfie does not match BVN record',
          'errorCode': 'BAD_REQUEST',
          'data': null,
        }),
      );

      await expectLater(
        authService.verifyBvn(bvn: '12345678901', selfieImageBase64: 'aGVsbG8='),
        throwsA(isA<KudiApiException>().having(
          (e) => e.message,
          'message',
          contains('Selfie does not match BVN record'),
        )),
      );
    });

    test('a validation 400 surfaces the VALIDATION_ERROR message', () async {
      adapter.queue(
        '/auth/kyc/verify-bvn',
        (_) => FakeHttpClientAdapter.jsonResponse(400, {
          'status': 'error',
          'message': 'Validation failed',
          'errorCode': 'VALIDATION_ERROR',
          'data': {
            'bvn': 'must match "^[0-9]{11}\$"',
          },
        }),
      );

      await expectLater(
        authService.verifyBvn(bvn: '12345', selfieImageBase64: 'aGVsbG8='),
        throwsA(isA<KudiApiException>().having(
          (e) => e.message,
          'message',
          contains('Validation failed'),
        )),
      );
    });

    test('a 500 surfaces as KudiServerException, not a generic wrap',
        () async {
      adapter.queue(
        '/auth/kyc/verify-bvn',
        (_) => FakeHttpClientAdapter.jsonResponse(500, {
          'status': 'error',
          'message': 'Internal error',
          'errorCode': 'INTERNAL_ERROR',
        }),
      );

      await expectLater(
        authService.verifyBvn(bvn: '12345678901', selfieImageBase64: 'aGVsbG8='),
        throwsA(isA<KudiServerException>()),
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

  group('Slice 6 — selectTier / getProfile / verifyAddress GPS', () {
    Map<String, dynamic> userResponse({
      String? tier,
      String? pendingTier,
      bool registrationComplete = false,
    }) {
      return {
        'customerId': 'KDT-TEST',
        'fullName': 'ABRAHAM CHIDUBEM',
        'phoneNumber': '+2348012345678',
        'email': 'a@b.com',
        'tier': tier,
        'pendingTier': pendingTier,
        'status': 'ACTIVE',
        'registrationComplete': registrationComplete,
      };
    }

    test('selectTier POSTs {tier: "PRO"} and maps tier + pendingTier from the '
        'server UserResponse', () async {
      await storage.saveUserModel(UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
      ));
      adapter.queueJson('/auth/select-tier', 200, {
        'status': 'success',
        'data': userResponse(tier: 'PRO', pendingTier: 'PRO'),
      });

      final updated = await authService.selectTier(tierNumber: 2);

      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.path, contains('/auth/select-tier'));
      final body = lastBody(adapter);
      expect(body['tier'], 'PRO');
      expect(updated.selectedTier, 2);
      expect(updated.pendingTier, 2);
    });

    test('selectTier maps MEGA for tier 3 and BASIC for tier 1', () async {
      await storage.saveUserModel(UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
      ));

      adapter.queueJson('/auth/select-tier', 200, {
        'status': 'success',
        'data': userResponse(tier: 'MEGA', pendingTier: 'MEGA'),
      });
      final mega = await authService.selectTier(tierNumber: 3);
      expect(lastBody(adapter)['tier'], 'MEGA');
      expect(mega.selectedTier, 3);
      expect(mega.pendingTier, 3);

      adapter.queueJson('/auth/select-tier', 200, {
        'status': 'success',
        'data': userResponse(tier: 'BASIC', pendingTier: 'BASIC'),
      });
      final basic = await authService.selectTier(tierNumber: 1);
      expect(lastBody(adapter)['tier'], 'BASIC');
      expect(basic.selectedTier, 1);
      expect(basic.pendingTier, 1);
    });

    test('getProfile returns the raw gateway data map (account + verification)',
        () async {
      adapter.queueJson('/profile', 200, {
        'status': 'success',
        'data': {
          'account': {
            'tier': 'PRO',
            'kycStatus': 'VERIFIED',
          },
          'verification': {
            'bvn': {'verified': true, 'masked': '****78901'},
            'nin': {'verified': true, 'masked': '****5678'},
            'address': {'status': 'PENDING_AGENT_VISIT'},
          },
        },
      });

      final profile = await profileService.getProfile();

      expect(adapter.requests.last.method, 'GET');
      expect(adapter.requests.last.path, contains('/profile'));
      expect(profile['account']['tier'], 'PRO');
      expect(profile['verification']['bvn']['masked'], '****78901');
      expect(profile['verification']['address']['status'],
          'PENDING_AGENT_VISIT');
    });

    test('updateProfile parses the real ProfileResponseDTO shape '
        '(profile/account/verification, not "user")', () async {
      await storage.saveUserModel(UserModel(
        userId: 'c-1',
        email: 'old@b.com',
        phoneNumber: '+2348012345678',
      ));
      adapter.queueJson('/profile/update-profile', 200, {
        'status': 'success',
        'data': {
          'profile': {
            'firstName': 'Ada',
            'lastName': 'Obi',
            'email': 'ada@b.com',
          },
          'account': {'tier': 'PRO'},
        },
      });

      final updated = await profileService.updateProfile(
        firstName: 'Ada',
        lastName: 'Obi',
        email: 'ada@b.com',
      );

      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.path, contains('/profile/update-profile'));
      // Proves the fix: this must come from the real 'profile' section, not
      // the optimistic fallback (which would also produce "Ada Obi" — the
      // email is the tell, since the fallback path never sets it).
      expect(updated.name, 'Ada Obi');
      expect(updated.email, 'ada@b.com');
    });

    test('verifyAddress sends latitude/longitude when captured (Slice 6 GPS)',
        () async {
      adapter.queueJson('/auth/kyc/verify-address', 200, {
        'status': 'success',
        'data': {
          'id': 1,
          'status': 'IN_PROGRESS',
          'addressStatus': 'PENDING_AGENT_VISIT',
        },
      });

      final summary = await authService.verifyAddress(
        houseNumber: '12',
        street: 'Broad Street',
        lga: 'Eti-Osa',
        city: 'Lagos',
        state: 'Lagos',
        utilityBillImageBase64: 'YmlsbA==',
        latitude: 6.4504,
        longitude: 3.3947,
      );

      final body = lastBody(adapter);
      expect(body['latitude'], 6.4504);
      expect(body['longitude'], 3.3947);
      expect(summary.addressStatus, AddressVerificationStatus.pendingAgentVisit);
    });

    test('verifyAddress omits latitude/longitude when not captured', () async {
      adapter.queueJson('/auth/kyc/verify-address', 200, {
        'status': 'success',
        'data': {
          'id': 1,
          'status': 'IN_PROGRESS',
          'addressStatus': 'PENDING_AGENT_VISIT',
        },
      });

      await authService.verifyAddress(
        houseNumber: '12',
        street: 'Broad Street',
        lga: 'Eti-Osa',
        city: 'Lagos',
        state: 'Lagos',
        utilityBillImageBase64: 'YmlsbA==',
      );

      final body = lastBody(adapter);
      expect(body.containsKey('latitude'), isFalse);
      expect(body.containsKey('longitude'), isFalse);
    });
  });

  group('Tier upgrade status (backend MEGA review lifecycle)', () {
    test('getTierUpgradeStatus GETs /auth/kyc/tier-upgrade/status and maps the '
        'latest request', () async {
      adapter.queueJson('/auth/kyc/tier-upgrade/status', 200, {
        'status': 'success',
        'data': {
          'targetTier': 'MEGA',
          'status': 'REVIEWING',
          'reviewNotes': 'awaiting admin decision',
          'submittedAt': '2026-08-18T10:00:00',
        },
      });

      final info = await authService.getTierUpgradeStatus();

      expect(adapter.requests.last.method, 'GET');
      expect(adapter.requests.last.path, contains('/auth/kyc/tier-upgrade/status'));
      expect(info.targetTier, 3);
      expect(info.status, TierUpgradeStatus.reviewing);
      expect(info.reviewNotes, 'awaiting admin decision');
    });

    test('an empty response maps to nulls (no active request)', () async {
      adapter.queueJson('/auth/kyc/tier-upgrade/status', 200, {
        'status': 'success',
        'data': <String, dynamic>{},
      });

      final info = await authService.getTierUpgradeStatus();

      expect(info.status, isNull);
      expect(info.targetTier, isNull);
      expect(info.reviewNotes, isNull);
    });
  });
}
