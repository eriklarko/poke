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
}
