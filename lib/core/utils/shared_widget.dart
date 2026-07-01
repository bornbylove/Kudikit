import 'package:flutter/material.dart';
import 'dart:math' as math;

const kTeal = Color(0xFF069494);
const kBgGrey = Color(0xFFf9f9f9);
const kTextDark = Color(0xFF151717);
const kTextMid = Color(0xFF666666);
const kTextLight = Color(0xFFAAAAAA);

// ── Circular Progress Badge ───────────────────────────────────────────────────

class CircularProgressBadge extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final double size;

  const CircularProgressBadge({
    super.key,
    required this.progress,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CircularProgressPainter(progress: progress),
        child: Center(
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w600,
              color: kTeal,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3;
    final strokeWidth = 3.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = kTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) => old.progress != progress;
}

// ── Standard Agent AppBar ─────────────────────────────────────────────────────

PreferredSizeWidget agentAppBar({
  required BuildContext context,
  required String title,
  double? progress,
  bool showProgress = true,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 18),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: kTextDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    centerTitle: true,
    actions: [
      if (showProgress && progress != null)
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircularProgressBadge(progress: progress),
        ),
    ],
  );
}

// ── Primary Bottom Button ─────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                onPressed != null ? kTeal : kTeal.withValues(alpha: 0.4),
            disabledBackgroundColor: kTeal.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 1,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

// ── Labelled Text Field ───────────────────────────────────────────────────────

class LabelledField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextInputType keyboardType;
  final Widget? suffix;
  final bool readOnly;
  final String? prefixText;

  const LabelledField({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.readOnly = false,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14, color: kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        hintStyle: const TextStyle(color: kTextLight, fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: kBgGrey,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kTeal, width: 1.5),
        ),
      ),
    );
  }
}

// ── Info Banner ───────────────────────────────────────────────────────────────

class InfoBanner extends StatelessWidget {
  final String message;

  const InfoBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: kTeal, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: kTextMid,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
