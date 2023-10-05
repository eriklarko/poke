import 'package:flutter/material.dart';

// PokeTappable represents any widget that can be tapped in this app. It's used
// to make all tap hilights consistent.
class PokeTappable extends StatelessWidget {
  final Widget child;
  final GestureTapCallback onTap;

  const PokeTappable({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: child,
    );
  }
}
