// lib/core/services/notification/notification_channels.dart
// ─────────────────────────────────────────────────────────────────────────────
// Single source of truth for notification channels, shared by
// NotificationService (main isolate), the FCM background handler (its own
// isolate), and AndroidManifest.xml.
//
// The channel id MUST match the manifest's
// `com.google.firebase.messaging.default_notification_channel_id`.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// High-importance channel used for FCM + local notifications.
const AndroidNotificationChannel kHighImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'Push Notifications',
  description: 'Important notifications from KudiKit.',
  importance: Importance.high,
);
