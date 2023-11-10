import 'package:flutter/material.dart';

class PokeLoadingIndicator extends StatelessWidget {
  final double width;
  final double height;

  const PokeLoadingIndicator._({
    required this.width,
    required this.height,
  });

  static const small = PokeLoadingIndicator._(width: 20, height: 20);
  static const large = PokeLoadingIndicator._(width: 200, height: 200);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: key,
      width: width,
      height: height,
      child: const CircularProgressIndicator(),
    );
  }
}
