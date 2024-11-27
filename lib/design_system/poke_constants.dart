import 'package:flutter/material.dart';

const double gridSize = 8;

class PokeConstants {
  static double space([int? multiplier]) {
    return gridSize * (multiplier ?? 1);
  }

  static SizedBox FixedSpacer([int? multiplier]) {
    double s = space(multiplier);
    return SizedBox(width: s, height: s);
  }

  static const ColorScheme colors = ColorScheme(
    primary: Colors.amber,
    onPrimary: Colors.white,
    //
    secondary: Color(0xFF03DAC6),
    onSecondary: Color(0xFF000000),
    //
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    //
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    //
    outline: Colors.black12,
    //
    brightness: Brightness.light,
  );
}
