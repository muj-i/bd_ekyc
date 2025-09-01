import 'package:flutter/material.dart';

class CutoutOverlayPainter extends CustomPainter {
  final double cutoutWidth;
  final double cutoutHeight;
  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;

  CutoutOverlayPainter({
    required this.cutoutWidth,
    required this.cutoutHeight,
    this.overlayColor = const Color.fromRGBO(255, 255, 255, 0.85),
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutoutWidth,
      height: cutoutHeight,
    );

    // Create a path for the overlay with a hole
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    // Draw white overlay with hole
    final paint = Paint()..color = overlayColor;
    canvas.drawPath(overlayPath, paint);

    // Draw border around cutout
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRect(cutoutRect, borderPaint);

    // Draw corner indicators
    _drawCornerIndicators(canvas, cutoutRect);
  }

  void _drawCornerIndicators(Canvas canvas, Rect cutoutRect) {
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 1;

    const cornerLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top),
      Offset(cutoutRect.left + cornerLength, cutoutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.top),
      Offset(cutoutRect.left, cutoutRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.top),
      Offset(cutoutRect.right - cornerLength, cutoutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.top),
      Offset(cutoutRect.right, cutoutRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom),
      Offset(cutoutRect.left + cornerLength, cutoutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.left, cutoutRect.bottom),
      Offset(cutoutRect.left, cutoutRect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.bottom),
      Offset(cutoutRect.right - cornerLength, cutoutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutoutRect.right, cutoutRect.bottom),
      Offset(cutoutRect.right, cutoutRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
