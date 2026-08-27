// lib/model/identity/liveness_state.dart
//
// State for the selfie-capture step of KYC onboarding. This step is a local
// CAPTURE ONLY — it never performs, claims, or persists a liveness result.
// The authoritative liveness check (and the selfie/registry match) happens
// server-side inside POST /auth/kyc/verify-bvn and /auth/kyc/verify-nin
// (DojahIdentityClient.verifyIdentity), which is where the PRD's "BVN
// validation API ... BVN number, selfie image" call is implemented.

enum LivenessStatus {
  initial,
  capturing,
  imageCaptured,
}

class LivenessState {
  final LivenessStatus status;

  /// Path to the captured selfie file. Retained (not the base64 payload)
  /// for as long as this flow is alive, since the BVN/NIN step needs to
  /// re-submit the same selfie to the auth-service. Cleared on [reset].
  final String? imagePath;

  const LivenessState({
    this.status = LivenessStatus.initial,
    this.imagePath,
  });

  LivenessState copyWith({
    LivenessStatus? status,
    String? imagePath,
  }) {
    return LivenessState(
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
