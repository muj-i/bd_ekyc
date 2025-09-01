import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6D0037);

  static const Color black = Color(0xFF101011);
  static const Color lightBlack = Color(0xFF2E2727);

  static const Color white = Color(0xFFFFFFFF);

  static const Color red = Color(0xFFE92727);
  static const Color lightRed = Color(0xFFC61E3C);

  static const Color yellow = Color(0xFFF4ED48);
  static const Color deepYellow = Color(0xFFf7a000);

  static const Color green = Color(0xFF008000);
  static const Color lightGreen = Color(0xFF33c301);

  static const Color blue = Color(0xFF1877F2);
  static const Color tealGreen = Color(0xFF2594A4);

  static const Color grey = Color(0xff575555);
  static const Color lightGrey = Color(0xffD8D8D8);

  static const Color transparent = Colors.transparent;

  static const Color blur = Color(0x80000000);

  static Map<int, Color> colorPaletteColors = {
    50: primary.withValues(alpha: 0.05),
    100: primary.withValues(alpha: 0.1),
    200: primary.withValues(alpha: 0.2),
    300: primary.withValues(alpha: 0.3),
    400: primary.withValues(alpha: 0.4),
    500: primary,
    600: primary.withValues(alpha: 0.6),
    700: primary.withValues(alpha: 0.7),
    800: primary.withValues(alpha: 0.8),
    900: primary.withValues(alpha: 0.9),
  };
}
