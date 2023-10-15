import 'package:flutter/material.dart';

class PokeHeader extends Text {
  const PokeHeader(super.text, {super.key})
      : super(
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        );
}

class PokeText extends Text {
  const PokeText(super.text, {super.key})
      : super(
          style: const TextStyle(
            fontSize: 18,
          ),
        );
}

class PokeFinePrint extends Text {
  const PokeFinePrint(super.text, {super.key})
      : super(
          style: const TextStyle(
            fontSize: 12,
          ),
        );
}
