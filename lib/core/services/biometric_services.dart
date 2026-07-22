// lib/core/services/biometric_services.dart
// ─────────────────────────────────────────────────────────────────────────────
// STUB — not yet wired.
//
// Fingerprint / Face biometric authentication. Requires the `local_auth`
// package, which is NOT yet declared in pubspec.yaml.
// ─────────────────────────────────────────────────────────────────────────────

/// Biometric authentication. All methods are stubs pending implementation.
class BiometricService {
  const BiometricService();

  /// TODO: return whether the device has usable biometrics enrolled.
  Future<bool> isAvailable() async {
    throw UnimplementedError(
        'BiometricService.isAvailable is a stub (needs local_auth).');
  }

  /// TODO: prompt the user for biometric auth; resolve true on success.
  Future<bool> authenticate({required String reason}) async {
    throw UnimplementedError(
        'BiometricService.authenticate is a stub (needs local_auth).');
  }
}
