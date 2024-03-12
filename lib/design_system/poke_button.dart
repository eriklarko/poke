import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';

// Standard buttons
class PokeButton extends StatelessWidget {
  final Widget Function(BuildContext) buildChild;

  const PokeButton._({
    required this.buildChild,
  });

  factory PokeButton.primary({
    Key? key,
    required Function()? onPressed,
    required String text,
  }) {
    return PokeButton._(
      buildChild: (_) => TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          padding: EdgeInsets.all(PokeConstants.space(4)),
        ),
        child: PokeText(text),
      ),
    );
  }

  factory PokeButton.icon(
    Icon icon, {
    Key? key,
    required Function()? onPressed,
  }) {
    return PokeButton._(
      buildChild: (_) => IconButton(
        key: key,
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildChild(context);
  }
}
