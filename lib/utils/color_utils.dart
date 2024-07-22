import 'dart:math';

import 'package:flutter/material.dart';

enum ColorFormat { sRGB, adobeRGB1998 }

class ColorUtils {
  static String rgbString(Color color) {
    return '${color.red}, ${color.green}, ${color.blue}';
  }

  static String hexString(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String hslString(Color color) {
    HSLColor hslColor = HSLColor.fromColor(color);
    return '${hslColor.hue.round()}, ${(hslColor.saturation * 100).round()}%, ${(hslColor.lightness * 100).round()}%';
  }

  static String hsvString(Color color) {
    HSVColor hsvColor = HSVColor.fromColor(color);
    return '${hsvColor.hue.round()}, ${(hsvColor.saturation * 100).round()}%, ${(hsvColor.value * 100).round()}%';
  }

  static String formatColor(Color color, ColorFormat format) {
    switch (format) {
      case ColorFormat.sRGB:
        return 'RGB(${color.red}, ${color.green}, ${color.blue})';
      case ColorFormat.adobeRGB1998:
        return adobeRGBString(color);
    }
  }

  static String adobeRGBString(Color color) {
    // Convert sRGB to XYZ
    List<double> xyz = _sRGBtoXYZ(color);

    // Convert XYZ to Adobe RGB
    List<double> adobeRGB = _XYZtoAdobeRGB(xyz);

    // Scale to 0-255 range and round
    int r = (adobeRGB[0] * 255).round().clamp(0, 255);
    int g = (adobeRGB[1] * 255).round().clamp(0, 255);
    int b = (adobeRGB[2] * 255).round().clamp(0, 255);

    return 'Adobe RGB($r, $g, $b)';
  }

  static List<double> _sRGBtoXYZ(Color color) {
    double r = _sRGBtoLinear(color.red / 255);
    double g = _sRGBtoLinear(color.green / 255);
    double b = _sRGBtoLinear(color.blue / 255);

    // sRGB to XYZ matrix (D65)
    double x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b;
    double y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
    double z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b;

    return [x, y, z];
  }

  static double _sRGBtoLinear(double c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  static List<double> _XYZtoAdobeRGB(List<double> xyz) {
    // XYZ to Adobe RGB matrix (D65)
    double r = 2.0413690 * xyz[0] - 0.5649464 * xyz[1] - 0.3446944 * xyz[2];
    double g = -0.9692660 * xyz[0] + 1.8760108 * xyz[1] + 0.0415560 * xyz[2];
    double b = 0.0134474 * xyz[0] - 0.1183897 * xyz[1] + 1.0154096 * xyz[2];

    // Adobe RGB gamma correction
    r = _linearToAdobeRGB(r);
    g = _linearToAdobeRGB(g);
    b = _linearToAdobeRGB(b);

    return [r, g, b];
  }

  static double _linearToAdobeRGB(double c) {
    return pow(max(0, min(1, c)), 1 / 2.19921875).toDouble();
  }
}
