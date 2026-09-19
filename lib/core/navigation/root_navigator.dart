// lib/core/navigation/root_navigator.dart
//
// The app's single Navigator key. Anything drawn ABOVE the Navigator via
// MaterialApp.builder (the session-lock overlay in main.dart) has no
// Navigator in its own BuildContext, so it cannot push routes or show dialogs
// through Navigator.of(context) — it goes through this key instead.

import 'package:flutter/widgets.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
