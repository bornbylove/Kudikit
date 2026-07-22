// lib/core/services/notification/fcm_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// STUB — not yet wired.
//
// Firebase Cloud Messaging (push). `firebase_messaging` is now in pubspec, and
// Firebase.initializeApp() runs (guarded) in main(). This still requires Firebase
// PLATFORM CONFIG to actually connect — google-services.json (Android) /
// GoogleService-Info.plist (iOS), or a generated firebase_options.dart.
// ─────────────────────────────────────────────────────────────────────────────

/// Foreground/registration side of FCM. Stubs pending implementation.
class FcmService {
  const FcmService();

  /// TODO: request permission, fetch the token, wire onMessage handlers,
  /// and register [fcmBackgroundHandler] via onBackgroundMessage.
  Future<void> init() async {
    throw UnimplementedError(
        'FcmService.init is a stub (needs firebase_messaging).');
  }

  /// TODO: return the current device FCM registration token.
  Future<String?> getToken() async {
    throw UnimplementedError(
        'FcmService.getToken is a stub (needs firebase_messaging).');
  }
}
