// lib/provider/auth/biometric_provider.dart
// Owns biometric enrollment: checks device support, and enable/disable
// which both (a) prompts the OS biometric dialog to confirm it actually
// works on this device before committing, and (b) tells the backend via
// SecurityService so /security/settings reflects it (kudikit_auth_service
// never receives biometric data itself — see biometric_service.dart).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/config/api_config.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/services/biometric_service.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:kudipay/services/profile_services.dart';
import 'package:kudipay/services/security_services.dart';
import 'package:kudipay/services/storage_services.dart';

final securityDioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: ApiConfig.securityBaseUrl,
    storage: StorageService.instance,
    connectivity: ConnectivityService.instance,
  );
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(ref.read(securityDioClientProvider));
});

/// Fixed routing for GET /profile & POST /profile/update-profile — see
/// profile_services.dart. Reuses the same proven :8181 client as
/// securityServiceProvider/dashboardServiceProvider.
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(
    ref.read(securityDioClientProvider),
    StorageService.instance,
  );
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Whether THIS device can even show a biometric prompt — independent of
/// whether the user has turned the feature on in Kudikit.
final biometricAvailabilityProvider =
    FutureProvider<BiometricAvailability>((ref) {
  return ref.read(biometricServiceProvider).checkAvailability();
});

/// PRD §2.2.1 §7 "Security Indicators: Last login timestamp and device" —
/// same GET /security/settings call session_lock_provider.dart already uses
/// for the auto-logout timeout, exposed here for the dashboard to watch too.
final securitySettingsProvider =
    FutureProvider.autoDispose<SecuritySettings?>((ref) {
  return ref.read(securityServiceProvider).getSecuritySettings();
});

/// The user's saved preference (persisted locally; mirrored server-side).
final biometricEnabledProvider = FutureProvider.autoDispose<bool>((ref) {
  return StorageService.instance.isBiometricEnabled();
});

class BiometricSettingsNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  BiometricSettingsNotifier(this._ref) : super(const AsyncValue.data(false)) {
    _load();
  }

  Future<void> _load() async {
    final enabled = await StorageService.instance.isBiometricEnabled();
    state = AsyncValue.data(enabled);
  }

  /// Prompts biometrics locally to confirm they work, then persists the
  /// preference locally and reports it to the backend. Throws
  /// [BiometricAuthException] (surfaced as AsyncError) if the OS prompt
  /// fails or is cancelled — enabling never silently no-ops.
  Future<void> enable() async {
    state = const AsyncValue.loading();
    try {
      final biometricService = _ref.read(biometricServiceProvider);
      final availability = await biometricService.checkAvailability();
      if (availability != BiometricAvailability.available) {
        throw BiometricAuthException(
          availability == BiometricAvailability.notEnrolled
              ? 'No fingerprint or face is set up on this device yet. Add one in your device settings first.'
              : 'This device does not support biometric authentication.',
        );
      }

      await biometricService.authenticate(
        reason: 'Confirm it\'s you to enable biometric login',
      );

      final type = await biometricService.biometricTypeLabel();
      await StorageService.instance.setBiometricEnabled(true);

      // Best-effort: local unlock still works even if this fails offline —
      // the preference re-syncs next time /security/settings is fetched.
      try {
        await _ref.read(securityServiceProvider).enableBiometric(type);
      } catch (_) {}

      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> disable() async {
    state = const AsyncValue.loading();
    try {
      await StorageService.instance.setBiometricEnabled(false);
      // The stored passcode only exists to serve biometric login.
      await StorageService.instance.deleteBiometricCredential();
      try {
        await _ref.read(securityServiceProvider).disableBiometric();
      } catch (_) {}
      state = const AsyncValue.data(false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final biometricSettingsProvider =
    StateNotifierProvider<BiometricSettingsNotifier, AsyncValue<bool>>((ref) {
  return BiometricSettingsNotifier(ref);
});
