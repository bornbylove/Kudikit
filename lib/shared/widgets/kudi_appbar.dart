// ============================================================================
// lib/formatting/widget/app_bar.dart
// Reusable KudiKit app bar with back button, title, and optional actions.
// Named KudiAppBar to avoid shadowing Flutter's built-in AppBar.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:kudipay/core/utils/responsive.dart';

class KudiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color titleColor;
  final double elevation;

  const KudiAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.backgroundColor = const Color(0xFFF9F9F9),
    this.titleColor = const Color(0xFF1A1A2E),
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: elevation,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back button
                if (showBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.chevron_left, size: 28),
                      color: const Color(0xFF1A1A2E),
                      splashRadius: 20,
                    ),
                  ),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 18),
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    fontFamily: 'PolySans',
                  ),
                ),

                // Actions
                if (actions != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline (non-PreferredSize) version for use inside Column/Stack layouts.
/// Matches the pattern used throughout existing screens.
class KudiInlineAppBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  const KudiInlineAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onBack ?? () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 28,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 18),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
              fontFamily: 'PolySans',
            ),
          ),
          if (trailing != null)
            Align(
              alignment: Alignment.centerRight,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
