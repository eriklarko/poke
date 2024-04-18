import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_tappable.dart';

import 'triangle_painter.dart';

class IconButtonWithTriangularBackground extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final GestureTapCallback onPressed;

  const IconButtonWithTriangularBackground({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TrianglePainter(
        strokeColor: color,
        strokeWidth: 10,
        paintingStyle: PaintingStyle.fill,
      ),
      child: PokeTappable(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.only(
            right: PokeConstants.space(),
            top: PokeConstants.space(),
            left: size + PokeConstants.space() * 1.5,
            bottom: size + PokeConstants.space() * 1.5,
          ),
          child: Icon(icon, size: size),
        ),
      ),
    );
  }
}
