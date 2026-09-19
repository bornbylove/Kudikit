// lib/services/biometric_service.dart
// Thin wrapper over local_auth (v3 API — LocalAuthException/
// LocalAuthExceptionCode, not the old PlatformException/error_codes.dart
// string constants) — the only place in the app that talks to the OS
// biometric APIs (Android BiometricPrompt / iOS Face ID & Touch ID via
// LocalAuthentication). Biometric auth never leaves the device: it just
// gates access to the already-cached session (see AppLockScreen), matching
// kudikit_auth_service's contract — POST /security/biometric/enable only
// ever records a preference flag server-side, there is no server endpoint
// that verifies a fingerprint/face.

import 'package:local_auth/local_auth.dart';

enum BiometricAvailability {
  /// Device has enrolled biometrics and can prompt for them now.
  available,

  /// Hardware exists but nothing is enrolled (e.g. no fingerprint added).
  notEnrolled,

  /// Device has no biometric hardware, or the OS/app can't use it.
  unsupported,
}

class BiometricAuthException implements Exception {
  final String message;
  final bool userCancelled;
  const BiometricAuthException(this.message, {this.userCancelled = false});
  @override
  String toString() => message;
}

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  Future<BiometricAvailability> checkAvailability() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return BiometricAvailability.unsupported;

      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return BiometricAvailability.unsupported;

      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) return BiometricAvailability.notEnrolled;

      return BiometricAvailability.available;
    } catch (_) {
      return BiometricAvailability.unsupported;
    }
  }

  /// The specific enrolled biometric type, for display and for the `type`
  /// field kudikit_auth_service's BiometricRequest expects
  /// ("FACE"/"FINGERPRINT"). Defaults to "FINGERPRINT" when the OS reports
  /// more than one or can't tell (matches Android's common case).
  Future<String> biometricTypeLabel() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return 'FACE';
      if (types.contains(BiometricType.iris)) return 'IRIS';
      return 'FINGERPRINT';
    } catch (_) {
      return 'FINGERPRINT';
    }
  }

  /// Prompts the OS biometric dialog. Returns true only on a genuine
  /// biometric success — throws [BiometricAuthException] for every other
  /// outcome (cancelled, locked out, not enrolled, etc.) so callers can
  /// show/skip an error message appropriately.
  Future<bool> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        sensitiveTransaction: true,
      );
      if (!ok) {
        throw const BiometricAuthException('Authentication failed.',
            userCancelled: true);
      }
      return true;
    } on BiometricAuthException {
      rethrow;
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
          throw const BiometricAuthException('Authentication cancelled.',
              userCancelled: true);
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
          throw const BiometricAuthException(
              'Biometrics are not set up on this device.');
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          throw const BiometricAuthException(
              'Too many attempts. Biometrics are temporarily locked — use your passcode.');
        default:
          throw BiometricAuthException(
              e.description ?? 'Authentication failed.');
      }
    } catch (_) {
      throw const BiometricAuthException('Authentication cancelled.',
          userCancelled: true);
    }
  }
}
