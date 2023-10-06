import 'package:flutter/material.dart';

class PokeModal extends Dialog {
  PokeModal({super.key, required child})
      : super(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: child,
            ),
          ),
        );
}
