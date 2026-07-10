import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';

import '../../core/constants/constant.dart';

class WhiteAppButton extends StatelessWidget {
  final String text;

  final GestureTapCallback press;

  const WhiteAppButton({super.key, required this.press, required this.text});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        style: TextButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5),
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
            side: BorderSide(
              color: AppColors.primaryTeal, // 👈 border color
              width: 0.5, // 👈 border width
            ),
          ),
        ),
        onPressed: press,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              color: AppColors.primaryTeal,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
