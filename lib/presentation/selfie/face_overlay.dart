import 'package:flutter/material.dart';

// // Face Overlay Painter
class FaceOverlayPainter extends CustomPainter {
  final bool faceDetected;

  FaceOverlayPainter({required this.faceDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = faceDetected ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final center = Offset(size.width / 2, size.height / 2 - 50);
    final radius = size.width * 0.35;

    // Draw oval for face
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 2.3,
    );

    canvas.drawOval(rect, paint);

    // Draw corner brackets
    final cornerLength = 30.0;
    final corners = [
      // Top-left
      [rect.left, rect.top, rect.left + cornerLength, rect.top],
      [rect.left, rect.top, rect.left, rect.top + cornerLength],
      // Top-right
      [rect.right - cornerLength, rect.top, rect.right, rect.top],
      [rect.right, rect.top, rect.right, rect.top + cornerLength],
      // Bottom-left
      [rect.left, rect.bottom - cornerLength, rect.left, rect.bottom],
      [rect.left, rect.bottom, rect.left + cornerLength, rect.bottom],
      // Bottom-right
      [rect.right, rect.bottom - cornerLength, rect.right, rect.bottom],
      [rect.right - cornerLength, rect.bottom, rect.right, rect.bottom],
    ];

    for (var corner in corners) {
      canvas.drawLine(
        Offset(corner[0], corner[1]),
        Offset(corner[2], corner[3]),
        paint..strokeWidth = 6,
      );
    }
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.faceDetected != faceDetected;
  }
}
