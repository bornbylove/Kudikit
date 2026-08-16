// lib/provider/identity/liveness_provider.dart
//
// Riverpod wiring for the Dojah liveness flow, following this app's
// established StateNotifier + StateNotifierProvider pattern (see
// lib/provider/auth/auth_provider.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import 'package:kudipay/model/identity/liveness_state.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/services/identity/dojah_client.dart';
import 'package:kudipay/services/identity/dojah_exceptions.dart';
import 'package:kudipay/services/identity/liveness_verification_service.dart';

// =============================================================================
// SERVICE PROVIDERS
// =============================================================================

final dojahClientProvider = Provider<DojahClient>((ref) {
  return DojahClient(connectivity: ConnectivityService.instance);
});

final livenessVerificationServiceProvider =
    Provider<LivenessVerificationService>((ref) {
  return LivenessVerificationService(ref.read(dojahClientProvider));
});

// =============================================================================
// LIVENESS NOTIFIER
// =============================================================================

class LivenessNotifier extends StateNotifier<LivenessState> {
  final LivenessVerificationService _service;

  LivenessNotifier(this._service) : super(const LivenessState());

  void startCapturing() {
    if (state.isSubmitting) return;
    state = const LivenessState(status: LivenessStatus.capturing);
  }

  /// Called once a photo has been taken/picked, before it's submitted —
  /// this is the "preview, allow retake" stage.
  void imageCaptured(String imagePath) {
    if (state.isSubmitting) return;
    state = LivenessState(
      status: LivenessStatus.imageCaptured,
      imagePath: imagePath,
    );
  }

  void retake() {
    if (state.isSubmitting) return;
    state = const LivenessState(status: LivenessStatus.capturing);
  }

  /// Submits [selfie] to Dojah. Guarded against duplicate submissions —
  /// a second call while one is already in flight is a no-op.
  Future<void> submit(XFile selfie) async {
    if (state.isSubmitting) return;
    state = state.copyWith(
      status: LivenessStatus.checkingLiveness,
      errorMessage: null,
    );

    try {
      final result = await _service.verify(selfie);
      final passed = result.livenessCheck == true;
      state = state.copyWith(
        status: passed ? LivenessStatus.success : LivenessStatus.failure,
        livenessPassed: passed,
        livenessProbability: result.livenessProbability,
        errorMessage: passed ? null : _failureMessage(result.faceDetected),
      );
    } on DojahException catch (e) {
      state = state.copyWith(
        status: LivenessStatus.failure,
        livenessPassed: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: LivenessStatus.failure,
        livenessPassed: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  String _failureMessage(bool? faceDetected) {
    if (faceDetected == false) {
      return 'We couldn\'t detect a face. Please try again.';
    }
    return 'We couldn\'t verify your liveness. Please try again.';
  }

  void reset() {
    state = const LivenessState();
  }
}

// =============================================================================
// MAIN PROVIDER
// =============================================================================

final livenessProvider = StateNotifierProvider<LivenessNotifier, LivenessState>(
  (ref) => LivenessNotifier(ref.read(livenessVerificationServiceProvider)),
);
