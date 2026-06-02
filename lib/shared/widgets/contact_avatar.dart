import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';


class ContactAvatar extends StatelessWidget {
  final String initials;
  final Color backgroundColor;
  final double size;
  final double fontSize;

  const ContactAvatar({
    super.key,
    required this.initials,
    required this.backgroundColor,
    this.size = 44,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}