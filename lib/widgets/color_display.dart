import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

class ColorDisplay extends StatelessWidget {
  final Color color;
  final ColorFormat format;

  const ColorDisplay({Key? key, required this.color, required this.format}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            color: color,
          ),
          Text(ColorUtils.formatColor(color, format)),
        ],
      ),
    );
  }
}