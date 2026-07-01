// lib/core/theme/app_theme.dart
//
// Single source of truth for all design tokens:
//   • AppColors    — every color used in the app
//   • AppTextStyles — static + responsive text styles
//
// Usage:
//   Color c = AppColors.primaryTeal;
//   TextStyle s = AppTextStyles.pageTitle;
//   TextStyle r = AppTextStyles.responsivePageTitle(context); // preferred in widgets

import 'package:flutter/material.dart';
import 'package:kudipay/core/utils/responsive.dart';

// =============================================================================
// AppColors
// =============================================================================

class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primaryTeal = Color(0xFF069494);
  static const Color primaryDark = Color(0xFF047878);
  static const Color accent = Color(0xFFEF9920);

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color backgroundScreen = Color(0xFFF9F9F9);
  static const Color backgroundGreen = Color(0xFFEDF7F1);
  static const Color backgroundInput = Color(0xFFFBFBFB);
  static const Color backgroundLight = Color(0xFFE8F5EE);
  static const Color searchBackground = Color(0xFFDCEFE4);
  static const Color white = Color(0xFFFFFFFF);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF151717);
  static const Color textTitle = Color(0xFF010F07);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textBody = Color(0xFF868686);
  static const Color textLight = Color(0xFFBDBDBD);

  // ── UI Elements ────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE0E0E0);
  static const Color inputBorder = Color(0xFFF3F2F2);
  static const Color error = Colors.red;

  // ── Avatars ────────────────────────────────────────────────────────────────
  static const Color avatarTeal = Color(0xFF26A69A);
  static const Color avatarDark = Color(0xFF37474F);
  static const Color avatarBlue = Color(0xFF5C6BC0);
  static const Color avatarLightBlue = Color(0xFF42A5F5);
  static const Color avatarRed = Color(0xFFC62828);
  static const Color avatarOrange = Color(0xFFFFA726);

  // ── Badges / Indicators ────────────────────────────────────────────────────
  static const Color checkGreen = Color(0xFF4CAF8A);
  static const Color inviteBadgeBackground = Color(0xFFDCEFE4);
  static const Color inviteBadgeText = Color(0xFF4CAF8A);
}

// =============================================================================
// AppTextStyles
// =============================================================================

/// Static styles are safe to use as `const` anywhere (no BuildContext needed).
/// Prefer the `responsive*` factory methods inside widgets for proper scaling
/// on tablets and large-screen devices.

class AppTextStyles {
  AppTextStyles._();

  // ── Static (fixed px) ──────────────────────────────────────────────────────

  static const TextStyle pageTitle = TextStyle(
    fontFamily: 'PolySans',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: 0.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'PolySans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static const TextStyle bodyGrey = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.3,
  );

  /// Legacy button style (kept for backward compatibility with constant.dart).
  /// Prefer [buttonText] for new code.
  static const TextStyle buttonTextLegacy = TextStyle(
    color: AppColors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'RaleWay',
  );

  static const TextStyle tabActive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTeal,
  );

  static const TextStyle tabInactive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static const TextStyle contactName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: 0.1,
  );

  static const TextStyle contactPhone = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    letterSpacing: 0.1,
  );

  static const TextStyle phoneInput = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static const TextStyle footerNote = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static const TextStyle inviteText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.inviteBadgeText,
  );

  static const TextStyle searchHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  // ── Responsive factory methods ─────────────────────────────────────────────
  // Use these inside widgets where BuildContext is available.

  static TextStyle responsivePageTitle(BuildContext context) => TextStyle(
        fontFamily: 'PolySans',
        fontSize: AppLayout.fontSize(context, 18),
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: 0.2,
      );

  static TextStyle responsiveBody(BuildContext context) => TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
      );

  static TextStyle responsiveButtonText(BuildContext context) => TextStyle(
        fontSize: AppLayout.fontSize(context, 15),
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 0.3,
      );

  static TextStyle responsiveLabel(BuildContext context) => TextStyle(
        fontSize: AppLayout.fontSize(context, 13),
        fontWeight: FontWeight.w400,
        color: AppColors.textGrey,
      );

  static TextStyle responsiveTabActive(BuildContext context) => TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTeal,
      );

  static TextStyle responsiveTabInactive(BuildContext context) => TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        fontWeight: FontWeight.w400,
        color: AppColors.textGrey,
      );

  static TextStyle responsiveContactName(BuildContext context) => TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        letterSpacing: 0.1,
      );

  static TextStyle responsiveFooterNote(BuildContext context) => TextStyle(
        fontSize: AppLayout.fontSize(context, 11),
        fontWeight: FontWeight.w400,
        color: AppColors.textGrey,
      );
}
