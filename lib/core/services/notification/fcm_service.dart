// lib/core/services/notification/fcm_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// STUB — not yet wired.
//
// Firebase Cloud Messaging (push). Requires the `firebase_messaging` package
// (NOT yet in pubspec — only firebase_core/firebase_auth are) plus
// Firebase.initializeApp() in main() (not yet called).
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
