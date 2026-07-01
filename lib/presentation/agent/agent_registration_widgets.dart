import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';

/// Shared agent-registration UI widgets used across registration steps.
class KudiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const KudiCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppLayout.scaleWidth(context, 12),
            offset: Offset(0, AppLayout.scaleHeight(context, 4)),
          ),
        ],
      ),
      child: child,
    );
  }
}

class KudiFieldLabel extends StatelessWidget {
  final String text;
  const KudiFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'PolySans',
          fontSize: AppLayout.fontSize(context, 13),
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      );
}

class KudiHintText extends StatelessWidget {
  final String text;
  const KudiHintText(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 11),
          color: AppColors.textLight,
        ),
      );
}

class KudiInputField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? prefixText;
  final bool readOnly;

  const KudiInputField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixText,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = AppLayout.scaleWidth(context, 14);
    final vPad = AppLayout.scaleHeight(context, 13);
    final radius = AppLayout.scaleWidth(context, 10);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        color: AppColors.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: TextStyle(
          fontSize: AppLayout.fontSize(context, 14),
          color: AppColors.textLight,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.backgroundScreen,
        contentPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide:
              const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
      ),
    );
  }
}

class KudiInfoBanner extends StatelessWidget {
  final String message;
  const KudiInfoBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 14)),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              color: AppColors.primaryTeal,
              size: AppLayout.scaleWidth(context, 16)),
          SizedBox(width: AppLayout.scaleWidth(context, 10)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KudiPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const KudiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 8),
        AppLayout.scaleWidth(context, 20),
        AppLayout.scaleHeight(context, 28),
      ),
      color: AppColors.backgroundScreen,
      child: SizedBox(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 52),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? AppColors.primaryTeal
                : AppColors.primaryTeal.withValues(alpha: 0.4),
            disabledBackgroundColor:
                AppColors.primaryTeal.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: AppLayout.scaleWidth(context, 22),
                  height: AppLayout.scaleWidth(context, 22),
                  child: const CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 1,
                    strokeCap: StrokeCap.round,
                  ),
                )
              : Text(label, style: AppTextStyles.responsiveButtonText(context)),
        ),
      ),
    );
  }
}

class KudiCircularProgress extends StatelessWidget {
  final double progress;

  const KudiCircularProgress({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final size = AppLayout.scaleWidth(context, 40);
    final percent = (progress * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(progress: progress),
        child: Center(
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    const sw = 3.0;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppColors.primaryTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
