import 'package:flutter/material.dart';

class PasscodeDotsIndicator extends StatelessWidget {
  final int length;
  final int filledCount;
  final bool showError;

  const PasscodeDotsIndicator({
    Key? key,
    required this.length,
    required this.filledCount,
    this.showError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: showError
            ? Colors.red.withValues(alpha: 0.1)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < filledCount
                    ? (showError ? Colors.red : const Color(0xFF069494))
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
