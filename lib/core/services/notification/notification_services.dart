// lib/core/services/notification/notification_services.dart
// ─────────────────────────────────────────────────────────────────────────────
// Local notifications: channel setup, display, permission, and tap handling.
// Built on flutter_local_notifications. Used by FcmService to surface FCM
// messages while the app is in the foreground (Android does not display them
// automatically in that state).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:kudipay/core/services/notification/notification_navigator_services.dart';

/// The Android channel FCM + local notifications post to. The id is mirrored in
/// AndroidManifest.xml (default_notification_channel_id).
const AndroidNotificationChannel kHighImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'Notifications',
  description: 'General notifications from KudiKit.',
  importance: Importance.high,
);

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;
  int _nextId = 0;

  /// Initialise the plugin, create the Android channel, request permission, and
  /// wire tap handling. Safe to call more than once.
  Future<void> init() async {
    if (_initialised) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      // Ask on first show() instead of at launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (response) =>
          NotificationNavigatorService.handlePayload(response.payload),
    );

    // Create the Android channel up front so importance is honoured.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(kHighImportanceChannel);
    await android?.requestNotificationsPermission();

    final darwin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await darwin?.requestPermissions(alert: true, badge: true, sound: true);

    // Handle a tap that cold-started the app from a local notification.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      NotificationNavigatorService.handlePayload(
          launch!.notificationResponse?.payload);
    }

    _initialised = true;
  }

  /// Display a local notification now.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        kHighImportanceChannel.id,
        kHighImportanceChannel.name,
        channelDescription: kHighImportanceChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    _nextId = (_nextId + 1) % 2147483647;
    try {
      await _plugin.show(_nextId, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('NotificationService.show failed: $e');
    }
  }
}
