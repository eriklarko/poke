import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_text.dart';

class PokeAppBar extends AppBar {
  PokeAppBar(BuildContext context, {super.key, String title = 'Poke 👉'})
      : super(
          title: PokeHeader(title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,

          // Stop the app bar turning darker while scrolling
          // https://stackoverflow.com/a/72773421
          scrolledUnderElevation: 0,
        );
}
