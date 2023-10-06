import 'package:flutter/material.dart';

// PokeTappable represents any widget that can be tapped in this app. It's used
// to make all tap hilights consistent.
class PokeTappable extends InkWell {
  const PokeTappable({super.key, required super.child, required super.onTap})
      : super();
}
