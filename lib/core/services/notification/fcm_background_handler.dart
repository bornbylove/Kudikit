// lib/core/services/notification/fcm_background_handler.dart
// ─────────────────────────────────────────────────────────────────────────────
// Top-level FCM background/terminated message handler.
//
// Runs in its own isolate, so it MUST initialise Firebase itself and stay a
// top-level function annotated with @pragma('vm:entry-point'). Registered from
// FcmService.init() via FirebaseMessaging.onBackgroundMessage(...).
//
// Notification-type messages are shown by the OS automatically while the app is
// backgrounded; this handler is where you'd process data-only messages (update
// local state, badges, etc.).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // The background isolate has no Firebase app yet — bring one up.
  await Firebase.initializeApp();
  debugPrint('[FCM bg] ${message.messageId} data=${message.data}');
  // TODO: process data-only background messages here if needed.
}
