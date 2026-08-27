// test/auth_provider_test.dart
//
// Verifies the 202 DEVICE_LINK integration points in the auth layer:
//   1. AuthNotifier.login() stores the challenge on `deviceVerificationRequired`
//      instead of calling completeSession (no "Malformed session" error).
//   2. DeviceLinkingNotifier drives the real verify-otp(DEVICE_LINK) →
//      login/verify-device → completeSession flow end-to-end.
// No real network — see FakeHttpClientAdapter.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/model/user/kyc_status.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/device_linking/device_linking_provider.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_http_client_adapter.dart';

class _AlwaysOnline implements ConnectivityChecker {
  @override
  Future<bool> hasInternetConnection() async => true;
}

class _Offline implements ConnectivityChecker {
  @override
  Future<bool> hasInternetConnection() async => false;
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

  Map<String, dynamic> authTokenEnvelope() => {
        'status': 'success',
        'data': {
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
          'tokenType': 'Bearer',
          'expiresIn': 3600,
          'user': {'customerId': 'c-1', 'email': 'a@b.com'},
        },
      };

  group('AuthNotifier.login — 202 DEVICE_LINK challenge', () {
    test('stores the challenge instead of completing a session', () async {
      adapter.queueJson('/auth/login', 202, {
        'status': 'success',
        'data': {
          'deviceVerificationRequired': true,
          'otpReference': 'otp-ref-202',
          'maskedIdentifier': 'u***8@gmail.com',
          'expiresInSeconds': 300,
        },
      });

      final notifier = AuthNotifier(authService, storage);

      await notifier.login(email: '+2348012345678', password: '284915');

      expect(notifier.state.requiresDeviceVerification, isTrue);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.deviceChallenge!.otpReference, 'otp-ref-202');
      expect(notifier.state.deviceChallenge!.maskedIdentifier,
          'u***8@gmail.com');
      expect(notifier.state.deviceChallenge!.expiresInSeconds, 300);
      // No session was persisted.
      expect(await storage.getAuthToken(), isNull);

      notifier.dispose();
    });

    test('does NOT throw "Malformed session response" on a 202', () async {
      adapter.queueJson('/auth/login', 202, {
        'status': 'success',
        'data': {
          'deviceVerificationRequired': true,
          'otpReference': 'otp-ref-202',
          'maskedIdentifier': 'u***8@gmail.com',
          'expiresInSeconds': 300,
        },
      });

      final notifier = AuthNotifier(authService, storage);

      await expectLater(
        notifier.login(email: '+2348012345678', password: '284915'),
        completes,
      );
      expect(notifier.state.requiresDeviceVerification, isTrue);

      notifier.dispose();
    });

    test('trusted-device 200 still completes the session normally', () async {
      adapter.queueJson('/auth/login', 200, authTokenEnvelope());

      final notifier = AuthNotifier(authService, storage);

      await notifier.login(email: '+2348012345678', password: '284915');

      expect(notifier.state.requiresDeviceVerification, isFalse);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(await storage.getAuthToken(), 'access-1');

      notifier.dispose();
    });

    test('throws if a 202 arrives without an otpReference', () async {
      adapter.queueJson('/auth/login', 202, {
        'status': 'success',
        'data': {
          'deviceVerificationRequired': true,
          'maskedIdentifier': 'u***8@gmail.com',
        },
      });

      final notifier = AuthNotifier(authService, storage);

      await expectLater(
        notifier.login(email: '+2348012345678', password: '284915'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('OTP reference'),
        )),
      );

      notifier.dispose();
    });
  });

  group('DeviceLinkingNotifier — real device verification flow', () {
    test('verifyCode drives verify-otp(DEVICE_LINK) → verify-device → '
        'onDeviceVerified(data)', () async {
      // 1. verify-otp for the DEVICE_LINK purpose.
      adapter.queueJson('/auth/verify-otp', 200, {
        'status': 'success',
        'data': {'otpReference': 'otp-ref-202'},
      });
      // 2. login/verify-device returns the full AuthTokenResponse envelope.
      adapter.queueJson('/auth/login/verify-device', 200, authTokenEnvelope());

      Map<String, dynamic>? completedData;
      final service = DeviceLinkingService(authService: authService);
      final notifier = DeviceLinkingNotifier(
        service,
        onDeviceVerified: (data) async => completedData = data,
      );

      notifier.startDeviceVerification(
        otpReference: 'otp-ref-202',
        identifier: '+2348012345678',
        maskedIdentifier: 'u***8@gmail.com',
      );

      final ok = await notifier.verifyCode('222335');

      expect(ok, isTrue);
      expect(notifier.state.data!.isVerified, isTrue);

      // verify-otp body carried the DEVICE_LINK purpose (requests[0]).
      final otpBody = adapter.requests[0].data;
      expect(otpBody['otpReference'], 'otp-ref-202');
      expect(otpBody['code'], '222335');
      expect(otpBody['purpose'], OtpPurpose.deviceLink);

      // verify-device reused the same persistent fingerprint as login
      // (requests[1]).
      final devBody = adapter.requests[1].data;
      expect(devBody['otpReference'], 'otp-ref-202');
      expect(devBody['deviceFingerprint'],
          matches(RegExp(r'^[0-9a-f]{32}$')));

      // completeSession data was handed to the auth layer.
      expect(completedData, isNotNull);
      expect(completedData!['accessToken'], 'access-1');
    });

    test('returns false and surfaces an error when there is no challenge '
        'seeded', () async {
      final service = DeviceLinkingService(authService: authService);
      final notifier = DeviceLinkingNotifier(service);

      final ok = await notifier.verifyCode('222335');

      expect(ok, isFalse);
      expect(notifier.state.error, contains('No active device verification'));
      expect(adapter.requests, isEmpty);

      notifier.dispose();
    });

    test('startDeviceVerification seeds the identifier for resend', () async {
      adapter.queueJson('/auth/send-otp', 200, {
        'status': 'success',
        'data': {'otpReference': 'otp-ref-resend'},
      });

      final service = DeviceLinkingService(authService: authService);
      final notifier = DeviceLinkingNotifier(service);

      notifier.startDeviceVerification(
        otpReference: 'otp-ref-202',
        identifier: '+2348012345678',
        maskedIdentifier: 'u***8@gmail.com',
      );

      await notifier.sendVerificationCode();

      final body = lastBody(adapter);
      expect(body['identifier'], '+2348012345678');
      expect(body['purpose'], OtpPurpose.deviceLink);

      notifier.dispose();
    });
  });

  group('AuthNotifier session restore — cache-first (Slice 4A)', () {
    test('restores an authenticated session from cached token+user WITHOUT '
        'calling GET /profile', () async {
      await storage.saveAuthToken('access-cached');
      await storage.saveRefreshToken('refresh-cached');
      await storage.saveUserModel(UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
        isSelfieVerified: true,
      ));

      final notifier = AuthNotifier(authService, storage);

      // Give the constructor's async _checkAuthStatus() a turn to settle.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user!.email, 'a@b.com');
      // KYC progress cached locally survives boot restore.
      expect(notifier.state.user!.isSelfieVerified, isTrue);
      // The auth-service has no /profile: boot must make ZERO network calls.
      expect(adapter.requests, isEmpty);

      notifier.dispose();
    });

    test('with no cached session, boot lands on unauthenticated', () async {
      final notifier = AuthNotifier(authService, storage);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(adapter.requests, isEmpty);

      notifier.dispose();
    });

    test('offline cached startup still restores the session', () async {
      await storage.saveAuthToken('access-cached');
      await storage.saveRefreshToken('refresh-cached');
      await storage.saveUserModel(UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
      ));

      final offlineClient = DioClient(
        baseUrl: 'https://gateway.test/api/v1',
        storage: storage,
        connectivity: _Offline(),
        dio: Dio(BaseOptions(baseUrl: 'https://gateway.test/api/v1')),
        refreshDio: Dio(BaseOptions(baseUrl: 'https://gateway.test/api/v1')),
      );
      final offlineAuth = AuthService(storage, offlineClient);
      final notifier = AuthNotifier(offlineAuth, storage);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isAuthenticated, isTrue);

      notifier.dispose();
    });
  });

  group('AuthNotifier.refreshKycStatus (Slice 4B)', () {
    test('GET /auth/kyc/status merges typed state, persists it, and publishes',
        () async {
      await storage.saveAuthToken('access-cached');
      await storage.saveRefreshToken('refresh-cached');
      await storage.saveUserModel(UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
        isSelfieVerified: true,
        isBvnVerified: true,
        kycStatus: KycStatus.verified,
      ));

      // SLICE 6 (MO-4): an authenticated boot fires its own best-effort KYC
      // reconciliation, so the endpoint is hit once by the constructor restore
      // and once by the explicit call below. Queue both responses.
      adapter.queueJson('/auth/kyc/status', 200, {
        'status': 'success',
        'data': {
          'status': 'MANUAL_REVIEW',
          'bvnVerified': true,
          'ninVerified': false,
          'livenessVerified': false,
          'idDocumentStatus': 'MANUAL_REVIEW',
          'addressStatus': 'NOT_STARTED',
          'requiresManualReview': true,
        },
      });
      // Boot reconciliation ALSO fires the internal tier-upgrade read
      // (best-effort; no active request -> empty payload).
      adapter.queueJson('/auth/kyc/tier-upgrade/status', 200, {
        'status': 'success',
        'data': <String, dynamic>{},
      });
      adapter.queueJson('/auth/kyc/status', 200, {
        'status': 'success',
        'data': {
          'status': 'MANUAL_REVIEW',
          'bvnVerified': true,
          'ninVerified': false,
          'livenessVerified': false,
          'idDocumentStatus': 'MANUAL_REVIEW',
          'addressStatus': 'NOT_STARTED',
          'requiresManualReview': true,
        },
      });

      final notifier = AuthNotifier(authService, storage);
      await Future<void>.delayed(Duration.zero);

      await notifier.refreshKycStatus();

      // Endpoints were hit (boot reconciliation + on-demand) with the
      // authenticated client.
      expect(adapter.requests.length, 3);
      expect(adapter.requests.every((r) =>
          r.path.contains('/auth/kyc/status') ||
          r.path.contains('/tier-upgrade/status')), isTrue);
      expect(
        adapter.requests
            .where((r) => r.path.contains('/tier-upgrade/status'))
            .length,
        1,
      );

      // Server typed state won over the cached optimistic state.
      final stateUser = notifier.state.user!;
      expect(stateUser.kycStatus, KycStatus.manualReview);
      expect(stateUser.idDocumentStatus, IdDocumentStatus.manualReview);
      expect(stateUser.requiresManualReview, isTrue);
      expect(stateUser.isSelfieVerified, isFalse);
      expect(stateUser.isKycComplete, isFalse);

      // The merged user was persisted for the next boot restore.
      final persisted = await storage.getUserModel();
      expect(persisted!.kycStatus, KycStatus.manualReview);

      notifier.dispose();
    });

    test('a network failure is swallowed and the session survives untouched',
        () async {
      await storage.saveAuthToken('access-cached');
      await storage.saveRefreshToken('refresh-cached');
      final cached = UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
        isSelfieVerified: true,
        kycStatus: KycStatus.inProgress,
      );
      await storage.saveUserModel(cached);

      adapter.queueJson('/auth/kyc/status', 500,
          {'status': 'error', 'message': 'boom'});

      final notifier = AuthNotifier(authService, storage);
      await Future<void>.delayed(Duration.zero);

      await notifier.refreshKycStatus();

      // Session is intact, cached KYC state untouched, no error surfaced.
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.user!.email, 'a@b.com');
      expect(notifier.state.user!.kycStatus, KycStatus.inProgress);
      expect(notifier.state.user!.isSelfieVerified, isTrue);
      expect(notifier.state.hasError, isFalse);

      final persisted = await storage.getUserModel();
      expect(persisted!.kycStatus, KycStatus.inProgress);

      notifier.dispose();
    });

    test('does nothing when there is no authenticated user', () async {
      final notifier = AuthNotifier(authService, storage);
      await Future<void>.delayed(Duration.zero);

      await notifier.refreshKycStatus();

      expect(adapter.requests, isEmpty);
      expect(notifier.state.isAuthenticated, isFalse);

      notifier.dispose();
    });
  });

  group('AuthNotifier KYC submissions (Slice 5)', () {
    Map<String, dynamic> kycEntity({
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
        'idDocumentStatus': idDocumentStatus,
        'addressStatus': addressStatus,
        'requiresManualReview': requiresManualReview,
      };
    }

    Future<AuthNotifier> seededNotifier() async {
      await storage.saveAuthToken('access-cached');
      await storage.saveRefreshToken('refresh-cached');
      await storage.saveUserModel(UserModel(
        userId: 'c-1',
        email: 'a@b.com',
        phoneNumber: '+2348012345678',
      ));
      final notifier = AuthNotifier(authService, storage);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isAuthenticated, isTrue);
      return notifier;
    }

    test('verifyBvn POSTs to /auth/kyc/verify-bvn and persists the '
        'authoritative summary via copyWithKyc', () async {
      adapter.queueJson('/auth/kyc/verify-bvn', 200, {
        'status': 'success',
        'data': kycEntity(),
      });

      final notifier = await seededNotifier();

      final summary = await notifier.verifyBvn(
        bvn: '12345678901',
        selfieImageBase64: 'aGVsbG8=',
      );

      final body = lastBody(adapter);
      expect(adapter.requests.last.path, contains('/auth/kyc/verify-bvn'));
      expect(body['bvn'], '12345678901');
      expect(body['selfieImageBase64'], 'aGVsbG8=');
      expect(summary.status, KycStatus.verified);

      final user = notifier.state.user!;
      expect(user.kycStatus, KycStatus.verified);
      expect(user.isBvnVerified, isTrue);
      expect(user.isSelfieVerified, isTrue); // livenessVerified side-effect
      expect(user.isKycComplete, isTrue);

      final persisted = await storage.getUserModel();
      expect(persisted!.kycStatus, KycStatus.verified);

      notifier.dispose();
    });

    test('verifyNin POSTs to /auth/kyc/verify-nin and preserves ninVerified',
        () async {
      adapter.queueJson('/auth/kyc/verify-nin', 200, {
        'status': 'success',
        'data': kycEntity(
          status: 'VERIFIED',
          ninVerified: true,
          bvnVerified: true,
        ),
      });

      final notifier = await seededNotifier();

      final summary = await notifier.verifyNin(
        nin: '12345678901',
        selfieImageBase64: 'aGVsbG8=',
      );

      final body = lastBody(adapter);
      expect(adapter.requests.last.path, contains('/auth/kyc/verify-nin'));
      expect(body['nin'], '12345678901');
      expect(body.containsKey('bvn'), isFalse);
      expect(summary.ninVerified, isTrue);

      final user = notifier.state.user!;
      expect(user.isNinVerified, isTrue);

      notifier.dispose();
    });

    test('verifyIdDocument POSTs front/back and persists idDocumentStatus=VERIFIED',
        () async {
      adapter.queueJson('/auth/kyc/verify-id-document', 200, {
        'status': 'success',
        'data': kycEntity(
          status: 'IN_PROGRESS',
          idDocumentStatus: 'VERIFIED',
        ),
      });

      final notifier = await seededNotifier();

      final summary = await notifier.verifyIdDocument(
        documentType: 'NATIONAL_ID',
        frontImageBase64: 'ZnJvbnQ=',
        backImageBase64: 'YmFjaw==',
      );

      final body = lastBody(adapter);
      expect(adapter.requests.last.path,
          contains('/auth/kyc/verify-id-document'));
      expect(body['documentType'], 'NATIONAL_ID');
      expect(summary.idDocumentStatus, IdDocumentStatus.verified);

      final user = notifier.state.user!;
      expect(user.idDocumentStatus, IdDocumentStatus.verified);
      expect(user.isDocumentVerified, isTrue);

      notifier.dispose();
    });

    test('verifyAddress persists PENDING_AGENT_VISIT and does NOT set '
        'isAddressVerified', () async {
      adapter.queueJson('/auth/kyc/verify-address', 200, {
        'status': 'success',
        'data': kycEntity(
          status: 'IN_PROGRESS',
          addressStatus: 'PENDING_AGENT_VISIT',
        ),
      });

      final notifier = await seededNotifier();

      final summary = await notifier.verifyAddress(
        houseNumber: '12',
        street: 'Broad Street',
        lga: 'Eti-Osa',
        city: 'Lagos',
        addressState: 'Lagos',
        utilityBillImageBase64: 'YmlsbA==',
      );

      final body = lastBody(adapter);
      expect(adapter.requests.last.path, contains('/auth/kyc/verify-address'));
      expect(body['houseNumber'], '12');
      expect(body['street'], 'Broad Street');
      expect(body['state'], 'Lagos');
      expect(body['utilityBillImageBase64'], 'YmlsbA==');
      expect(summary.addressStatus, AddressVerificationStatus.pendingAgentVisit);

      final user = notifier.state.user!;
      expect(user.addressStatus, AddressVerificationStatus.pendingAgentVisit);
      expect(user.isAddressVerified, isFalse);

      notifier.dispose();
    });

    test('a 200 MANUAL_REVIEW is persisted but NOT treated as verified',
        () async {
      adapter.queueJson('/auth/kyc/verify-bvn', 200, {
        'status': 'success',
        'data': kycEntity(
          status: 'MANUAL_REVIEW',
          bvnVerified: false,
          livenessVerified: false,
          requiresManualReview: true,
        ),
      });

      final notifier = await seededNotifier();

      final summary = await notifier.verifyBvn(
        bvn: '12345678901',
        selfieImageBase64: 'aGVsbG8=',
      );

      expect(summary.status, KycStatus.manualReview);
      expect(summary.requiresManualReview, isTrue);

      final user = notifier.state.user!;
      expect(user.kycStatus, KycStatus.manualReview);
      expect(user.requiresManualReview, isTrue);
      expect(user.isBvnVerified, isFalse);
      expect(user.isKycComplete, isFalse);

      notifier.dispose();
    });

    test('a 400 rejection surfaces the message AND reconciles the persisted '
        'REJECTED state via GET /auth/kyc/status', () async {
      adapter.queue(
        '/auth/kyc/verify-bvn',
        (_) => FakeHttpClientAdapter.jsonResponse(400, {
          'status': 'error',
          'message': 'Selfie does not match BVN record',
          'errorCode': 'BAD_REQUEST',
          'data': null,
        }),
      );
      adapter.queueJson('/auth/kyc/status', 200, {
        'status': 'success',
        'data': kycEntity(
          status: 'REJECTED',
          bvnVerified: false,
          livenessVerified: false,
          requiresManualReview: false,
        ),
      });

      final notifier = await seededNotifier();

      await expectLater(
        notifier.verifyBvn(bvn: '12345678901', selfieImageBase64: 'aGVsbG8='),
        throwsA(isA<KudiApiException>().having(
          (e) => e.message,
          'message',
          contains('Selfie does not match BVN record'),
        )),
      );

      // The 400 rejection is reconciled via a follow-up GET status.
      expect(
        adapter.requests.map((r) => r.path).where(
            (p) => p.contains('/auth/kyc/status')),
        isNotEmpty,
      );
      final user = notifier.state.user!;
      expect(user.kycStatus, KycStatus.rejected);
      expect(user.isBvnVerified, isFalse);

      notifier.dispose();
    });

    test('submissions throw without an authenticated user and make no calls',
        () async {
      final notifier = AuthNotifier(authService, storage);
      await Future<void>.delayed(Duration.zero);

      await expectLater(
        notifier.verifyBvn(bvn: '12345678901', selfieImageBase64: 'aGVsbG8='),
        throwsA(isA<KudiApiException>()),
      );
      expect(adapter.requests, isEmpty);

      notifier.dispose();
    });
  });
}