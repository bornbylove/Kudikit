// test/liveness_provider_test.dart
//
// State-transition tests for LivenessNotifier (Slice 7.5).
//
// The selfie step is a local CAPTURE ONLY: it performs no KYC provider calls
// and makes no liveness claim. The authoritative liveness + selfie/registry
// match happens server-side inside POST /auth/kyc/verify-bvn | verify-nin
// (kudikit_auth_service). These tests pin that invariant — the provider must
// never transition to a "verified/success" state and never touch the network.

import 'package:flutter_test/flutter_test.dart';
import 'package:kudipay/model/identity/liveness_state.dart';
import 'package:kudipay/provider/identity/liveness_provider.dart';

void main() {
  late LivenessNotifier notifier;

  setUp(() {
    notifier = LivenessNotifier();
  });

  test('starts in LivenessStatus.initial', () {
    expect(notifier.state.status, LivenessStatus.initial);
    expect(notifier.state.imagePath, isNull);
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

  test('the selfie step never claims a verified/success liveness result', () {
    notifier.startCapturing();
    notifier.imageCaptured('/tmp/selfie.jpg');
    // There is no success/verified status on this step at all — it is a
    // capture-only stage; liveness is established server-side during BVN/NIN.
    expect(notifier.state.status, LivenessStatus.imageCaptured);
  });

  test('reset() returns to the initial state and clears the image path', () {
    notifier.imageCaptured('/tmp/selfie.jpg');
    notifier.reset();
    expect(notifier.state.status, LivenessStatus.initial);
    expect(notifier.state.imagePath, isNull);
  });
}