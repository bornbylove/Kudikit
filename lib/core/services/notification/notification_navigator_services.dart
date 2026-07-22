// lib/core/services/notification/notification_navigator_services.dart
// ─────────────────────────────────────────────────────────────────────────────
// Routes notification taps to the correct screen.
//
// Holds a global navigator key so navigation can happen from notification
// callbacks that have no BuildContext. Wire [navigatorKey] into
// MaterialApp.navigatorKey (done in main.dart).
//
// PAYLOAD CONVENTION
//   Notification taps carry a payload that is a JSON object. If it contains a
//   `route` key matching an AppRoutes name, we navigate there. Everything else
//   is ignored (safe no-op). The optional `args` value is forwarded as the
//   route arguments — only send it for routes that accept a plain value.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:flutter/material.dart';

class NotificationNavigatorService {
  const NotificationNavigatorService._();

  /// Attach to MaterialApp.navigatorKey to enable context-free navigation.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Handles a local-notification tap payload (a JSON string).
  static void handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = json.decode(payload);
      if (decoded is Map<String, dynamic>) {
        handleData(decoded);
      }
    } catch (_) {
      // Not JSON — treat the whole payload as a bare route name.
      _navigate(payload, null);
    }
  }

  /// Handles an FCM data map (from onMessageOpenedApp / getInitialMessage).
  static void handleData(Map<String, dynamic> data) {
    final route = data['route'];
    if (route is String && route.isNotEmpty) {
      _navigate(route, data['args']);
    }
  }

  static void _navigate(String route, Object? arguments) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    try {
      navigator.pushNamed(route, arguments: arguments);
    } catch (e) {
      debugPrint('NotificationNavigatorService: could not open "$route": $e');
    }
  }
}
