import 'package:flutter/material.dart';

// Standard button
class PokeButton extends StatelessWidget {
  final GestureTapCallback onPressed;
  final Widget child;

  const PokeButton({super.key, required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: child);
  }
}
