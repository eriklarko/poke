import 'package:flutter/material.dart';

// Standard button
class PokeButton extends TextButton {
  PokeButton({
    super.key,
    required super.onPressed,
    required String text,
  }) : super(
          child: Text(text),
        );
}
