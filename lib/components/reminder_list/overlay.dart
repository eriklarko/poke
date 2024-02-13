import 'package:flutter/material.dart';

class Overlay extends StatelessWidget {
  final Widget child;

  const Overlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
