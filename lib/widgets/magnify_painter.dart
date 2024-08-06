import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MagnifyPainter extends CustomPainter {
  final ui.Image image;
  final double borderRadius;
  final Color centerSquareColor;

  MagnifyPainter(this.image, {
    this.borderRadius = 8.0,
    this.centerSquareColor = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create a rounded rectangle path
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        dst,
        Radius.circular(borderRadius),
      ));

    // Clip the canvas with the rounded rectangle path
    canvas.clipPath(path);

    // Draw the image
    canvas.drawImageRect(image, src, dst, Paint());

    // Draw a border
    final borderPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, borderPaint);

    // Draw the center square
    final centerSquareSize = size.width / 9; // Adjust this value to change the size of the center square
    final centerSquare = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: centerSquareSize,
      height: centerSquareSize,
    );

    final centerSquarePaint = Paint()
      ..color = centerSquareColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(centerSquare, centerSquarePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}