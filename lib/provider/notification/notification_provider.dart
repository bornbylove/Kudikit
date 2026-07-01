import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/dio_client.dart';

import 'package:kudipay/presentation/notification/notification_preferences.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/services/notification_preference_services.dart';
import 'package:flutter_riverpod/legacy.dart';
// ==================== NOTIFICATION PROVIDERS ====================

// FIXED: was constructing NotificationPreferencesService() with no args —
// hardcoded wrong URL and no token, guaranteed 401 in production.
final notificationPreferencesServiceProvider =
    Provider<NotificationPreferencesService>((ref) {
  final token = ref.watch(authTokenProvider);
  return NotificationPreferencesService(
    baseUrl: kBaseUrl,
    authToken: token,
  );
});

// State notifier for notification preferences
class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final NotificationPreferencesService _service;

  NotificationPreferencesNotifier(this._service)
      : super(const AsyncValue.loading()) {
    loadPreferences();
  }

  /// Load preferences from server or local storage
  Future<void> loadPreferences() async {
    state = const AsyncValue.loading();

    try {
      // Try to load from local storage first for instant UI
      final localPrefs = await _service.loadLocalPreferences();
      state = AsyncValue.data(localPrefs);

      // Then fetch from server to sync
      final serverPrefs = await _service.fetchPreferences();
      state = AsyncValue.data(serverPrefs);

      // Save to local storage
      await _service.savePreferencesLocally(serverPrefs);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Toggle a specific preference
  Future<void> togglePreference(String key, bool value) async {
    final currentPrefs = state.value;
    if (currentPrefs == null) return;

    // Optimistically update UI
    final updatedPrefs = _updatePreferenceByKey(currentPrefs, key, value);
    state = AsyncValue.data(updatedPrefs);

    try {
      // Update on server
      final success = await _service.updateSinglePreference(key, value);

      if (success) {
        // Save to local storage
        await _service.savePreferencesLocally(updatedPrefs);
      } else {
        // Revert on failure
        state = AsyncValue.data(currentPrefs);
      }
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentPrefs);
    }
  }

  /// Update all preferences at once
  Future<void> updateAllPreferences(NotificationPreferences preferences) async {
    state = const AsyncValue.loading();

    try {
      final success = await _service.updatePreferences(preferences);

      if (success) {
        state = AsyncValue.data(preferences);
        await _service.savePreferencesLocally(preferences);
      } else {
        throw Exception('Failed to update preferences');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Helper to update preference by key
  NotificationPreferences _updatePreferenceByKey(
    NotificationPreferences prefs,
    String key,
    bool value,
  ) {
    switch (key) {
      // Transaction
      case 'transactionSuccess':
        return prefs.copyWith(transactionSuccess: value);
      case 'depositNotification':
        return prefs.copyWith(depositNotification: value);
      case 'withdrawalNotification':
        return prefs.copyWith(withdrawalNotification: value);
      case 'largeTransactionAlert':
        return prefs.copyWith(largeTransactionAlert: value);

      // Bills & Reminders
      case 'billPaymentReminder':
        return prefs.copyWith(billPaymentReminder: value);
      case 'failedBillPaymentAlert':
        return prefs.copyWith(failedBillPaymentAlert: value);

      // Rewards & Offers
      case 'rewardEarnedAlert':
        return prefs.copyWith(rewardEarnedAlert: value);
      case 'rewardExpiryAlert':
        return prefs.copyWith(rewardExpiryAlert: value);
      case 'promotionalOffers':
        return prefs.copyWith(promotionalOffers: value);
      case 'partnerOffers':
        return prefs.copyWith(partnerOffers: value);

      // App Updates & Tips
      case 'newFeatureAnnouncements':
        return prefs.copyWith(newFeatureAnnouncements: value);
      case 'tutorialPrompt':
        return prefs.copyWith(tutorialPrompt: value);
      case 'feedbackRequest':
        return prefs.copyWith(feedbackRequest: value);
      case 'announcementBanners':
        return prefs.copyWith(announcementBanners: value);

      default:
        return prefs;
    }
  }
}

// Provider for notification preferences
final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferences>>((ref) {
  final service = ref.watch(notificationPreferencesServiceProvider);
  return NotificationPreferencesNotifier(service);
});
