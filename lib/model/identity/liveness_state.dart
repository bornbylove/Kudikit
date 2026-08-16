// lib/model/identity/liveness_state.dart
//
// State for the Dojah liveness-verification flow. Mirrors the shape of
// SelfieState (lib/usecases/selfie_state.dart) — plain class + copyWith —
// but keyed off an explicit status enum instead of loose booleans, since
// this flow has more distinct stages than the existing selfie flow does.

enum LivenessStatus {
  initial,
  capturing,
  imageCaptured,
  checkingLiveness,
  success,
  failure,
}

class LivenessState {
  final LivenessStatus status;

  /// Path to the captured selfie file. Retained (not the base64 payload)
  /// for as long as this flow is alive, since a future BVN/NIN step needs
  /// to re-submit the same selfie — see LivenessVerificationService's doc
  /// comment. Cleared on [reset].
  final String? imagePath;

  /// True once the Dojah response's `entity.liveness.liveness_check` field
  /// came back exactly `true`. This is the only success condition — no
  /// probability threshold is applied.
  final bool livenessPassed;

  /// Retained for future business rules/auditing. Not used to gate success.
  final double? livenessProbability;

  /// User-safe message only — never a raw API response or exception detail.
  final String? errorMessage;

  const LivenessState({
    this.status = LivenessStatus.initial,
    this.imagePath,
    this.livenessPassed = false,
    this.livenessProbability,
    this.errorMessage,
  });

  bool get isSubmitting => status == LivenessStatus.checkingLiveness;

  LivenessState copyWith({
    LivenessStatus? status,
    String? imagePath,
    bool? livenessPassed,
    double? livenessProbability,
    String? errorMessage,
  }) {
    return LivenessState(
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      livenessPassed: livenessPassed ?? this.livenessPassed,
      livenessProbability: livenessProbability ?? this.livenessProbability,
      errorMessage: errorMessage,
    );
  }
}
