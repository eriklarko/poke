import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_text.dart';

// Standard button
class PokeButton extends StatelessWidget {
  final Function() onPressed;
  final String text;
  final ButtonStyle Function(BuildContext) style;

  const PokeButton._({
    super.key,
    required this.onPressed,
    required this.text,
    required this.style,
  });

  factory PokeButton.primary({
    Key? key,
    required Function() onPressed,
    required String text,
  }) {
    return PokeButton._(
      key: key,
      onPressed: onPressed,
      text: text,
      style: (_) => TextButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: style(context),
      child: PokeText(text),
    );
  }
}
