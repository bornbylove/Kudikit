// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF069494); // teal/green brand
  static const Color primaryDark = Color(0xFF2DA898);
  static const Color background = Color(0xFFF2F2F7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color tabUnselected = Color(0xFF8E8E93);
  static const Color divider = Color(0xFFE5E5EA);
  static const Color chipUnselected = Color(0xFFFFFFFF);
  static const Color chipUnselectedText = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.cardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}
