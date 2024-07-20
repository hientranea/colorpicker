import 'package:flutter/material.dart';

class ColorUtils {
  static String rgbString(Color color) {
    return '${color.red}, ${color.green}, ${color.blue}';
  }

  static String hexString(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
