import 'package:flutter/material.dart';

class PokeLoadingIndicator extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;
  final double? value;

  const PokeLoadingIndicator._({
    required this.width,
    required this.height,
    this.color,
    this.value,
  });

  const PokeLoadingIndicator.small({Color? color, double? value})
      : this._(width: 20, height: 20, color: color, value: value);

  const PokeLoadingIndicator.large({Color? color, double? value})
      : this._(width: 200, height: 200, color: color, value: value);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: key,
      width: width,
      height: height,
      child: CircularProgressIndicator(
        value: value,
        valueColor: AlwaysStoppedAnimation<Color?>(color),
      ),
    );
  }
}
