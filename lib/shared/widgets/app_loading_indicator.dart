// ===========================================================================
// app_loading_indicator.dart
// Standardized circular loading indicator that matches the login page style.
//
// The login page uses:
//   SizedBox(width: 22, height: 22,
//     child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1))
//
// For use OUTSIDE buttons (on white/light backgrounds), use:
//   AppLoadingIndicator()           — teal, size 22, strokeWidth 2
//
// For use INSIDE colored buttons (like on the login button), use:
//   AppLoadingIndicator.button()    — white, size 22, strokeWidth 1
//
// To replace a full-page CircularProgressIndicator:
//   AppLoadingIndicator.fullPage()  — centered on screen
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:kudipay/core/utils/responsive.dart';

class AppLoadingIndicator extends StatelessWidget {
  final Color color;
  final double size;
  final double strokeWidth;

  /// Standard on-page indicator (teal on light background)
  const AppLoadingIndicator({
    super.key,
    this.color = const Color(0xFF069494),
    this.size = 22,
    this.strokeWidth = 1,
  });

  /// Inside a teal/colored button — white, thin stroke, matches login page exactly
  const AppLoadingIndicator.button({
    super.key,
    this.color = Colors.white,
    this.size = 22,
    this.strokeWidth = 1,
  });

  /// Full-page centered loading state
  factory AppLoadingIndicator.fullPage({Key? key}) = _FullPageLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.scaleWidth(context, size),
      height: AppLayout.scaleWidth(context, size),
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

/// Full-page centered version
class _FullPageLoadingIndicator extends AppLoadingIndicator {
  const _FullPageLoadingIndicator({super.key})
      : super(
          color: const Color(0xFF069494),
          size: 28,
          strokeWidth: 2,
        );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: AppLayout.scaleWidth(context, size),
        height: AppLayout.scaleWidth(context, size),
        child: CircularProgressIndicator(
          color: color,
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }
}