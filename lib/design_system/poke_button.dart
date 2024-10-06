import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_tappable.dart';
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
    return PokeButton._primary(
      key: key,
      text: text,
      onPressed: onPressed,
      background: Colors.amber,
      foreground: Colors.white,
    );
  }

  factory PokeButton.primaryDangerous({
    Key? key,
    required Function()? onPressed,
    required String text,
  }) {
    return PokeButton._primary(
      key: key,
      text: text,
      onPressed: onPressed,
      background: Colors.red,
      foreground: Colors.white,
    );
  }

  factory PokeButton._primary({
    Key? key,
    required Function()? onPressed,
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return PokeButton._(
      buildChild: (_) => TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: EdgeInsets.all(PokeConstants.space(4)),
        ),
        child: PokeText(text),
      ),
    );
  }

  factory PokeButton.small({
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
          padding: EdgeInsets.all(PokeConstants.space()),
        ),
        child: PokeText(text),
      ),
    );
  }

  factory PokeButton.icon(
    IconData icon, {
    Key? key,
    String? text,
    double? iconSize,
    Color? color,
    required Function()? onPressed,
  }) {
    return PokeButton._(
      buildChild: (_) => PokeTappable(
        key: key,
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: color),
            if (text != null) PokeText(text, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildChild(context);
  }
}
