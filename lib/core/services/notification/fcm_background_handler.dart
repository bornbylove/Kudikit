// lib/core/services/notification/fcm_background_handler.dart
// ─────────────────────────────────────────────────────────────────────────────
// STUB — not yet wired.
//
// The background/terminated push handler. Requires `firebase_messaging`.
// When implemented, the parameter becomes a `RemoteMessage`, and the function
// MUST stay top-level and be annotated with @pragma('vm:entry-point') so it can
// run in its own isolate, then be registered via
// FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler).
// ─────────────────────────────────────────────────────────────────────────────

/// Handles push messages received while the app is backgrounded or terminated.
///
/// [message] is typed `Object?` for now; it becomes `RemoteMessage` once
/// `firebase_messaging` is added.
Future<void> fcmBackgroundHandler(Object? message) async {
  // TODO: process the background push payload (e.g. update local state / badge).
}
