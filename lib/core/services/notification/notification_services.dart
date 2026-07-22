// lib/core/services/notification/notification_services.dart
// ─────────────────────────────────────────────────────────────────────────────
// STUB — not yet wired.
//
// Local notifications (channels, display, tap handling). Requires the
// `flutter_local_notifications` package, which is NOT yet in pubspec.yaml.
// ─────────────────────────────────────────────────────────────────────────────

/// Displays and manages local notifications. Stubs pending implementation.
class NotificationService {
  const NotificationService();

  /// TODO: initialise plugin, create Android channels, set tap callbacks.
  Future<void> init() async {
    throw UnimplementedError(
        'NotificationService.init is a stub (needs flutter_local_notifications).');
  }

  /// TODO: display a local notification.
  Future<void> show({required String title, required String body}) async {
    throw UnimplementedError(
        'NotificationService.show is a stub (needs flutter_local_notifications).');
  }
}
