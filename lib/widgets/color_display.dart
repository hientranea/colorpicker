import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

class ColorDisplay extends StatelessWidget {
  final Color color;

  const ColorDisplay({Key? key, required this.color}) : super(key: key);

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
          Text('RGB: ${ColorUtils.rgbString(color)}'),
          Text('Hex: ${ColorUtils.hexString(color)}'),
        ],
      ),
    );
  }
}
