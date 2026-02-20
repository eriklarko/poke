import 'package:flutter/material.dart';

/// Inpsired by the `clock` library, this factory does what `clock.now` does for
/// `DateTime.now()` but for `GlobalKey`
// TODO: How does thread-safety work in dart? :) this is good enough for my use-case though as I'll only using it in tests
class KeyFactory {
  static GlobalKey? _next;

  static GlobalKey newGlobalKey({String? debugLabel}) {
    return _next ?? GlobalKey(debugLabel: debugLabel);
  }

  static void setGlobalKey(GlobalKey key) {
    _next = key;
  }
}
