// lib/core/services/notification/notification_navigator_services.dart
// ─────────────────────────────────────────────────────────────────────────────
// STUB — not yet wired.
//
// Routes a notification tap to the correct screen. Holds a global navigator key
// so navigation can occur from notification callbacks that have no BuildContext.
// To activate, pass [navigatorKey] to MaterialApp.navigatorKey.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';

/// Navigates in response to notification taps. Payload routing is a stub.
class NotificationNavigatorService {
  const NotificationNavigatorService();

  /// Wire this into MaterialApp.navigatorKey to enable context-free navigation.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// TODO: parse [payload] and navigate to the matching route.
  void handlePayload(String? payload) {
    throw UnimplementedError(
        'NotificationNavigatorService.handlePayload is a stub.');
  }
}
