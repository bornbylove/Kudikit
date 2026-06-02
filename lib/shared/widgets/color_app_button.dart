import 'package:flutter/material.dart';

import '../../core/constant/constant.dart';

class ColorAppButton extends StatelessWidget {
  final String text;

  final GestureTapCallback press;

  const ColorAppButton({Key? key, required this.press, required this.text})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    // const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5),
          backgroundColor: const Color(0xFF069494),
          disabledBackgroundColor:
                      const Color(0xFF069494).withValues(alpha: 0.5),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(28))),
        ),
        onPressed: press,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontFamily: 'PolySans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
