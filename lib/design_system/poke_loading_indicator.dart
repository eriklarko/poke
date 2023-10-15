import 'package:flutter/material.dart';

class PokeLoadingIndicator extends StatelessWidget {
  final double width;
  final double height;

  const PokeLoadingIndicator._({
    super.key,
    required this.width,
    required this.height,
  });

  factory PokeLoadingIndicator.small({Key? key}) {
    return PokeLoadingIndicator._(
      key: key,
      width: 20,
      height: 20,
    );
  }

  factory PokeLoadingIndicator.large({Key? key}) {
    return PokeLoadingIndicator._(
      key: key,
      width: 200,
      height: 200,
    );
  }

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
