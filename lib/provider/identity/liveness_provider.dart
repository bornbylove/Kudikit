// lib/provider/identity/liveness_provider.dart
//
// Riverpod wiring for the selfie-capture step of KYC onboarding, following
// this app's established StateNotifier + StateNotifierProvider pattern.
//
// THIS STEP MAKES NO KYC PROVIDER CALLS. The captured selfie is held in
// [LivenessState.imagePath] purely so the BVN/NIN step can re-encode and
// submit it to the auth-service (POST /auth/kyc/verify-bvn | verify-nin).
// Liveness verification and selfie/registry matching are performed
// server-side by kudikit_auth_service; the mobile never talks to a KYC
// provider directly and never claims an authoritative liveness result.

import 'package:flutter_riverpod/legacy.dart';

import 'package:kudipay/model/identity/liveness_state.dart';

// =============================================================================
// LIVENESS NOTIFIER
// =============================================================================

class LivenessNotifier extends StateNotifier<LivenessState> {
  LivenessNotifier() : super(const LivenessState());

  void startCapturing() {
    if (state.status == LivenessStatus.imageCaptured) return;
    state = const LivenessState(status: LivenessStatus.capturing);
  }

  /// Called once a photo has been taken/picked, before the user confirms —
  /// this is the "preview, allow retake" stage.
  void imageCaptured(String imagePath) {
    state = LivenessState(
      status: LivenessStatus.imageCaptured,
      imagePath: imagePath,
    );
  }

  void retake() {
    state = const LivenessState(status: LivenessStatus.capturing);
  }

  void reset() {
    state = const LivenessState();
  }
}

// =============================================================================
// MAIN PROVIDER
// =============================================================================

final livenessProvider =
    StateNotifierProvider<LivenessNotifier, LivenessState>(
  (ref) => LivenessNotifier(),
);
