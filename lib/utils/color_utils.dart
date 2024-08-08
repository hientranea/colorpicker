import 'dart:math';

import 'package:flutter/material.dart';

enum ColorFormat { sRGB, adobeRGB1998, HSB, CMYK, LAB  }

class ColorUtils {
  static String rgbString(Color color) {
    return '${color.red}, ${color.green}, ${color.blue}';
  }

  static String hexString(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}'.toUpperCase();
  }

  static String hslString(Color color) {
    HSLColor hslColor = HSLColor.fromColor(color);
    return '${hslColor.hue.round()}, ${(hslColor.saturation * 100).round()}%, ${(hslColor.lightness * 100).round()}%';
  }

  static String hsvString(Color color) {
    HSVColor hsvColor = HSVColor.fromColor(color);
    return '${hsvColor.hue.round()}, ${(hsvColor.saturation * 100).round()}%, ${(hsvColor.value * 100).round()}%';
  }

  static String hsbString(Color color) {
    var r = color.red.clamp(0, 255);
    var g = color.green.clamp(0, 255);
    var b = color.blue.clamp(0, 255);

    // Convert RGB to the range 0-1
    double rf = r / 255;
    double gf = g / 255;
    double bf = b / 255;

    double maxVal = max(rf, max(gf, bf));
    double minVal = min(rf, min(gf, bf));

    double delta = maxVal - minVal;

    double hue = 0;
    double saturation = 0;
    double brightness = maxVal;

    if (delta != 0) {
      if (maxVal == rf) {
        hue = ((gf - bf) / delta) % 6;
      } else if (maxVal == gf) {
        hue = (bf - rf) / delta + 2;
      } else {
        hue = (rf - gf) / delta + 4;
      }

      hue *= 60;
      if (hue < 0) hue += 360;

      saturation = maxVal != 0 ? delta / maxVal : 0;
    }

    return "${hue}, ${saturation * 100}, ${brightness * 100}";
  }

  static String cmykString(Color color) {
    var r = color.red;
    var g = color.green;
    var b = color.blue;

    // Ensure RGB values are in the correct range (0-255)
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    // Convert RGB to 0-1 range
    double r1 = r / 255;
    double g1 = g / 255;
    double b1 = b / 255;

    // Calculate K (black)
    double k = 1 - max(r1, max(g1, b1));

    // Calculate C, M, Y
    double c = k == 1 ? 0 : (1 - r1 - k) / (1 - k);
    double m = k == 1 ? 0 : (1 - g1 - k) / (1 - k);
    double y = k == 1 ? 0 : (1 - b1 - k) / (1 - k);

    // Round to 3 decimal places and ensure values are between 0 and 1
    int cPercent = (c * 100).round();
    int mPercent = (m * 100).round();
    int yPercent = (y * 100).round();
    int kPercent = (k * 100).round();

    return "${cPercent.clamp(0, 100)}%, ${mPercent.clamp(0, 100)}%, ${yPercent.clamp(0, 100)}%, ${kPercent.clamp(0, 100)}%";
  }

  static String labString(Color color) {
    // Convert RGB to XYZ
    List<double> xyz = _sRGBtoXYZ(color);

    // Convert XYZ to LAB
    List<double> lab = _XYZtoLAB(xyz);

    return '${lab[0].round()}, ${lab[1].round()}, ${lab[2].round()}';
  }

  static List<double> _XYZtoLAB(List<double> xyz) {
    double x = xyz[0] / 95.047;
    double y = xyz[1] / 100.0;
    double z = xyz[2] / 108.883;

    x = x > 0.008856 ? pow(x, 1/3).toDouble() : (7.787 * x) + (16 / 116);
    y = y > 0.008856 ? pow(y, 1/3).toDouble() : (7.787 * y) + (16 / 116);
    z = z > 0.008856 ? pow(z, 1/3).toDouble() : (7.787 * z) + (16 / 116);

    double l = (116 * y) - 16;
    double a = 500 * (x - y);
    double b = 200 * (y - z);

    return [l, a, b];
  }

  static String formatColor(Color color, ColorFormat format) {
    switch (format) {
      case ColorFormat.sRGB:
        return 'RGB(${color.red}, ${color.green}, ${color.blue})';
      case ColorFormat.adobeRGB1998:
        return adobeRGBString(color);
      case ColorFormat.HSB:
        return 'HSB(${hsbString(color)})';
      case ColorFormat.LAB:
        return 'LAB(${labString(color)})';
      default:
        return "";
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
