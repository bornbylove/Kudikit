// test/dojah_client_test.dart
//
// Deterministic tests for DojahClient — endpoint/method/body/header
// correctness and status-code-to-exception mapping. No real network calls
// (see FakeHttpClientAdapter) and no real Dojah credentials — the injected
// test Dio carries throwaway header values that only assert wiring, not
// anything that touches the real Dojah API.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/config/dio_client.dart' show ConnectivityChecker;
import 'package:kudipay/services/identity/dojah_client.dart';
import 'package:kudipay/services/identity/dojah_exceptions.dart';

import 'helpers/fake_http_client_adapter.dart';

class _AlwaysOnline implements ConnectivityChecker {
  @override
  Future<bool> hasInternetConnection() async => true;
}

class _AlwaysOffline implements ConnectivityChecker {
  @override
  Future<bool> hasInternetConnection() async => false;
}

const _validLivenessBody = {
  'entity': {
    'face': {'face_detected': true, 'multiface_detected': false},
    'liveness': {'liveness_check': true, 'liveness_probability': 97},
  },
};

void main() {
  late FakeHttpClientAdapter adapter;
  late DojahClient client;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    final dio = Dio(BaseOptions(
      baseUrl: 'https://dojah.test',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'test-secret-key',
        'AppId': 'test-app-id',
      },
    ))
      ..httpClientAdapter = adapter;

    client = DojahClient(dio: dio, connectivity: _AlwaysOnline());
  });

  group('request shape', () {
    test('POSTs to /api/v1/ml/liveness with the image in the body', () async {
      adapter.queueJson('/api/v1/ml/liveness', 200, _validLivenessBody);

      await client.checkLiveness('base64payload');

      expect(adapter.requests, hasLength(1));
      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.path, contains('/api/v1/ml/liveness'));
      expect(req.data, {'image': 'base64payload'});
    });

    test('sends Authorization as the raw secret (no Bearer prefix) and AppId',
        () async {
      adapter.queueJson('/api/v1/ml/liveness', 200, _validLivenessBody);

      await client.checkLiveness('base64payload');

      final headers = adapter.requests.single.headers;
      expect(headers['Authorization'], 'test-secret-key');
      expect(headers['AppId'], 'test-app-id');
    });
  });

  group('successful response parsing', () {
    test('returns a LivenessResponse reflecting liveness_check == true',
        () async {
      adapter.queueJson('/api/v1/ml/liveness', 200, _validLivenessBody);

      final result = await client.checkLiveness('base64payload');

      expect(result.livenessCheck, true);
      expect(result.livenessProbability, 97);
      expect(result.faceDetected, true);
    });

    test('returns liveness_check == false without throwing', () async {
      adapter.queueJson('/api/v1/ml/liveness', 200, {
        'entity': {
          'face': {'face_detected': true},
          'liveness': {'liveness_check': false, 'liveness_probability': 4},
        },
      });

      final result = await client.checkLiveness('base64payload');

      expect(result.livenessCheck, false);
    });
  });

  group('HTTP error mapping', () {
    test('400 maps to DojahInvalidImageException', () async {
      adapter.queueJson('/api/v1/ml/liveness', 400, {'error': 'bad image'});
      await expectLater(
        client.checkLiveness('x'),
        throwsA(isA<DojahInvalidImageException>()),
      );
    });

    test('401 maps to DojahUnauthorizedException', () async {
      adapter.queueJson('/api/v1/ml/liveness', 401, {'error': 'unauthorized'});
      await expectLater(
        client.checkLiveness('x'),
        throwsA(isA<DojahUnauthorizedException>()),
      );
    });

    test('402 maps to DojahInsufficientBalanceException', () async {
      adapter.queueJson('/api/v1/ml/liveness', 402, {'error': 'no balance'});
      await expectLater(
        client.checkLiveness('x'),
        throwsA(isA<DojahInsufficientBalanceException>()),
      );
    });

    test('429 maps to DojahRateLimitedException', () async {
      adapter.queueJson('/api/v1/ml/liveness', 429, {'error': 'rate limited'});
      await expectLater(
        client.checkLiveness('x'),
        throwsA(isA<DojahRateLimitedException>()),
      );
    });

    test('500 maps to DojahServerException', () async {
      adapter.queueJson('/api/v1/ml/liveness', 500, {'error': 'boom'});
      await expectLater(
        client.checkLiveness('x'),
        throwsA(isA<DojahServerException>()),
      );
    });

    test('a malformed 200 response (missing entity) maps to DojahMalformedResponseException',
        () async {
      adapter.queueJson('/api/v1/ml/liveness', 200, {'unexpected': 'shape'});
      await expectLater(
        client.checkLiveness('x'),
        throwsA(isA<DojahMalformedResponseException>()),
      );
    });
  });

  group('connectivity', () {
    test('throws DojahNetworkException without making a request when offline',
        () async {
      final offlineClient = DojahClient(
        dio: Dio(BaseOptions(baseUrl: 'https://dojah.test'))
          ..httpClientAdapter = adapter,
        connectivity: _AlwaysOffline(),
      );

      await expectLater(
        offlineClient.checkLiveness('x'),
        throwsA(isA<DojahNetworkException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });
}
