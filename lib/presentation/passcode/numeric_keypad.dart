import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspacePressed;

  const NumericKeypad({
    Key? key,
    required this.onNumberPressed,
    required this.onBackspacePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 20),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 20),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 20),
        _buildRow(['scan', '0', 'back']),
      ],
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number == 'scan') {
          return _buildSpecialButton(
            icon: Icons.qr_code_scanner,
            onPressed: () {
              // Handle biometric/scan action
            },
          );
        } else if (number == 'back') {
          return _buildSpecialButton(
            icon: Icons.backspace_outlined,
            onPressed: onBackspacePressed,
            color: Colors.red,
          );
        } else {
          return _buildNumberButton(number);
        }
      }).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => onNumberPressed(number),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 28,
          color: color ?? Colors.grey[600],
        ),
      ),
    );
  }
}
