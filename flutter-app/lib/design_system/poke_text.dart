import 'package:flutter/material.dart';

TextStyle regularText(Color? color) => TextStyle(
      fontSize: 18,
      color: color,
    );

const headerText = TextStyle(
  fontSize: 30,
  fontWeight: FontWeight.bold,
);

const finePrint = TextStyle(
  fontSize: 12,
);

class PokeText extends Text {
  PokeText(
    super.text, {
    super.key,
    Color? color,
    bool center = false,
  }) : super(
          style: regularText(color),
          textAlign: center ? TextAlign.center : TextAlign.start,
        );

  const PokeText.withStyle(
    super.text,
    TextStyle style, {
    super.key,
  }) : super(style: style);
}

class PokeHeader extends PokeText {
  const PokeHeader(String text, {super.key})
      : super.withStyle(
          text,
          headerText,
        );
}

class PokeFinePrint extends PokeText {
  const PokeFinePrint(String text, {super.key})
      : super.withStyle(
          text,
          finePrint,
        );
}
