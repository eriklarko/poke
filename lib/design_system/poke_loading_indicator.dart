import 'package:flutter/material.dart';

class PokeLoadingIndicator extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const PokeLoadingIndicator._({
    required this.width,
    required this.height,
    this.color,
  });

  const PokeLoadingIndicator.small({Color? color})
      : this._(width: 20, height: 20, color: color);

  const PokeLoadingIndicator.large({Color? color})
      : this._(width: 200, height: 200, color: color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: key,
      width: width,
      height: height,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color?>(color),
      ),
    );
  }
}
