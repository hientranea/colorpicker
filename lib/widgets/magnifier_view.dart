import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'magnify_painter.dart';

class MagnifierView extends StatelessWidget {
  final ui.Image? image;
  final double size;

  const MagnifierView({Key? key, this.image, this.size = 80}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (image == null) return const SizedBox();

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: MagnifyPainter(image!),
      ),
    );
  }
}
