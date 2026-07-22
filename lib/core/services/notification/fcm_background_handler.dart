// lib/core/services/notification/fcm_background_handler.dart
// ─────────────────────────────────────────────────────────────────────────────
// Top-level FCM background/terminated message handler.
//
// Runs in its own isolate, so it MUST initialise Firebase itself and stay a
// top-level function annotated with @pragma('vm:entry-point'). Registered from
// FcmService.init() via FirebaseMessaging.onBackgroundMessage(...).
//
// Notification-payload messages are shown by the OS automatically while the app
// is backgrounded — showing our own would double up. So we only surface a local
// notification for data-only messages.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:kudipay/core/services/notification/notification_channels.dart';
import 'package:kudipay/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The background isolate has no Firebase app yet — bring one up.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('[FCM bg] ${message.messageId} data=${message.data}');

  // OS shows notification-payload messages automatically; only data-only
  // messages need a manual local notification.
  if (message.notification == null && message.data.isNotEmpty) {
    await _showDataOnlyNotification(message);
  }
}

/// Shows a local notification for a data-only background message. Runs in a
/// separate isolate, so it uses a fresh FlutterLocalNotificationsPlugin.
Future<void> _showDataOnlyNotification(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    const InitializationSettings(android: androidSettings),
  );

  final title = message.data['title'] as String? ?? 'KudiKit';
  final body = message.data['body'] as String? ??
      'Open KudiKit to see the details.';

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      kHighImportanceChannel.id,
      kHighImportanceChannel.name,
      channelDescription: kHighImportanceChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    details,
    payload: json.encode(message.data),
  );
}
