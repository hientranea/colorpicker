import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'magnify_painter.dart';

class MagnifierView extends StatelessWidget {
  final ui.Image? image;

  const MagnifierView({Key? key, this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (image == null) return const SizedBox();

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: CustomPaint(
        painter: MagnifyPainter(image!),
      ),
    );
  }
}
