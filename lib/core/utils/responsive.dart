import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLayout {
  /* -------------------- SIZE -------------------- */

  static Size size(BuildContext context) => MediaQuery.of(context).size;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double statusBarHeight(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  /* -------------------- DEVICE TYPE -------------------- */

  static bool isMobile(BuildContext context) => width(context) < 600;

  static bool isTablet(BuildContext context) =>
      width(context) >= 600 && width(context) < 1024;

  static bool isDesktop(BuildContext context) => width(context) >= 1024;

  /* -------------------- ORIENTATION -------------------- */

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /* -------------------- RESPONSIVE SCALING -------------------- */
  /// Base design size: 375 x 812 (iPhone X)
  static double scaleWidth(BuildContext context, double base) =>
      width(context) * (base / 375);

  static double scaleHeight(BuildContext context, double base) =>
      height(context) * (base / 812);

  static double fontSize(BuildContext context, double base) =>
      scaleWidth(context, base);

  /* -------------------- COMMON UI HELPERS -------------------- */

  static double logoSize(BuildContext context) {
    return isPortrait(context) ? height(context) * 0.05 : width(context) * 0.05;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: scaleWidth(context, 20),
      vertical: scaleHeight(context, 16),
    );
  }

  /* -------------------- SYSTEM UI -------------------- */

  static void hideSystemBars() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );
  }

  static void showSystemBars() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /* -------------------- ORIENTATION CONTROL -------------------- */

  static Future<void> lockPortrait() async {
    await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );
  }

  static Future<void> lockLandscape() async {
    await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft],
    );
  }

  static Future<void> unlockOrientation() async {
    await SystemChrome.setPreferredOrientations(
      DeviceOrientation.values,
    );
  }
}
