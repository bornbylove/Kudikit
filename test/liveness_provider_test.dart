// test/liveness_provider_test.dart
//
// State-transition tests for LivenessNotifier, driven through a real
// LivenessVerificationService/DojahClient pair wired to a fake HTTP adapter
// (no real network calls, no real Dojah credentials).

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kudipay/model/identity/liveness_state.dart';
import 'package:kudipay/provider/identity/liveness_provider.dart';
import 'package:kudipay/services/identity/dojah_client.dart';
import 'package:kudipay/services/identity/liveness_verification_service.dart';

import 'helpers/fake_http_client_adapter.dart';

XFile _fakeSelfie() =>
    XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'selfie.jpg');

const _successBody = {
  'entity': {
    'face': {'face_detected': true},
    'liveness': {'liveness_check': true, 'liveness_probability': 90},
  },
};

void main() {
  late FakeHttpClientAdapter adapter;
  late LivenessNotifier notifier;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://dojah.test'))
      ..httpClientAdapter = adapter;
    final client = DojahClient(dio: dio);
    final service = LivenessVerificationService(client);
    notifier = LivenessNotifier(service);
  });

  test('starts in LivenessStatus.initial', () {
    expect(notifier.state.status, LivenessStatus.initial);
  });

  test('startCapturing() moves to capturing', () {
    notifier.startCapturing();
    expect(notifier.state.status, LivenessStatus.capturing);
  });

  test('imageCaptured() moves to imageCaptured and stores the path', () {
    notifier.startCapturing();
    notifier.imageCaptured('/tmp/selfie.jpg');
    expect(notifier.state.status, LivenessStatus.imageCaptured);
    expect(notifier.state.imagePath, '/tmp/selfie.jpg');
  });

  test('retake() returns to capturing and clears the captured path', () {
    notifier.imageCaptured('/tmp/selfie.jpg');
    notifier.retake();
    expect(notifier.state.status, LivenessStatus.capturing);
    expect(notifier.state.imagePath, isNull);
  });

  test('submit() moves synchronously into checkingLiveness before resolving',
      () async {
    adapter.queueJson('/api/v1/ml/liveness', 200, _successBody);
    notifier.imageCaptured('/tmp/selfie.jpg');

    final future = notifier.submit(_fakeSelfie());
    expect(notifier.state.status, LivenessStatus.checkingLiveness);
    await future;
  });

  test('submit() -> success when liveness_check is true', () async {
    adapter.queueJson('/api/v1/ml/liveness', 200, _successBody);

    await notifier.submit(_fakeSelfie());

    expect(notifier.state.status, LivenessStatus.success);
    expect(notifier.state.livenessPassed, true);
    expect(notifier.state.livenessProbability, 90);
  });

  test('submit() -> failure when liveness_check is false (not a thrown error)',
      () async {
    adapter.queueJson('/api/v1/ml/liveness', 200, {
      'entity': {
        'face': {'face_detected': true},
        'liveness': {'liveness_check': false, 'liveness_probability': 10},
      },
    });

    await notifier.submit(_fakeSelfie());

    expect(notifier.state.status, LivenessStatus.failure);
    expect(notifier.state.livenessPassed, false);
    expect(notifier.state.errorMessage, isNotNull);
  });

  test('submit() -> failure with a safe message on an HTTP error (401)',
      () async {
    adapter.queueJson('/api/v1/ml/liveness', 401, {'error': 'unauthorized'});

    await notifier.submit(_fakeSelfie());

    expect(notifier.state.status, LivenessStatus.failure);
    expect(notifier.state.errorMessage, isNotNull);
    expect(notifier.state.errorMessage, isNot(contains('401')));
  });

  test('submit() -> networkError-style failure surfaces a safe message on connectionError',
      () async {
    adapter.queue('/api/v1/ml/liveness', (options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });

    await notifier.submit(_fakeSelfie());

    expect(notifier.state.status, LivenessStatus.failure);
    expect(notifier.state.errorMessage, contains('internet'));
  });

  test('submit() prevents a duplicate submission while one is in flight',
      () async {
    // Only one response queued — if the guard failed and a second real
    // request went out, it would hit "no response queued".
    adapter.queueJson('/api/v1/ml/liveness', 200, _successBody);

    final selfie = _fakeSelfie();
    final first = notifier.submit(selfie);
    final second = notifier.submit(selfie); // must be a no-op
    await Future.wait([first, second]);

    expect(adapter.requests, hasLength(1));
    expect(notifier.state.status, LivenessStatus.success);
  });

  test('reset() returns to the initial state', () async {
    adapter.queueJson('/api/v1/ml/liveness', 200, _successBody);
    await notifier.submit(_fakeSelfie());

    notifier.reset();

    expect(notifier.state.status, LivenessStatus.initial);
    expect(notifier.state.imagePath, isNull);
    expect(notifier.state.livenessPassed, false);
    expect(notifier.state.errorMessage, isNull);
  });
}
