import 'package:colorpicker/utils/constants.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MagnifyPainter extends CustomPainter {
  final ui.Image image;
  final double borderRadius;

  MagnifyPainter(this.image, {this.borderRadius = 8.0});

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
      ..color = AppColors.backgroundGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}