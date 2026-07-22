// lib/core/services/notification/fcm_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// Firebase Cloud Messaging (push).
//
// Requires Firebase to already be initialised (Firebase.initializeApp() runs in
// main()) and platform config to be present: google-services.json (Android,
// done) / GoogleService-Info.plist (iOS — must also be added to the Runner
// target in Xcode). On iOS, real delivery additionally needs an APNs key
// configured in the Firebase console and the Push Notifications capability.
//
// Responsibilities:
//   • request notification permission
//   • register the background message handler
//   • foreground messages  → shown via NotificationService (local notification)
//   • tap on a message      → routed via NotificationNavigatorService
//   • expose the device FCM token
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'package:kudipay/core/services/notification/fcm_background_handler.dart';
import 'package:kudipay/core/services/notification/notification_navigator_services.dart';
import 'package:kudipay/core/services/notification/notification_services.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialised = false;

  /// Wire up FCM. Assumes Firebase.initializeApp() has already run.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    // Background/terminated messages (own isolate).
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

    await _messaging.requestPermission();

    // Show notifications while the app is foregrounded on iOS.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground: surface the message as a local notification.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App opened from a background notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => NotificationNavigatorService.handleData(message.data),
    );

    // App cold-started from a notification tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => NotificationNavigatorService.handleData(initial.data),
      );
    }

    final token = await getToken();
    debugPrint('[FCM] token: $token');
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    NotificationService.instance.show(
      title: notification.title ?? 'KudiKit',
      body: notification.body ?? '',
      payload: json.encode(message.data),
    );
  }

  /// The current device FCM registration token (null if unavailable).
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }
}
