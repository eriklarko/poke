import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_button.dart';

class PokeModal extends Dialog {
  PokeModal({super.key, required child, PokeButton? actionButton})
      : super(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: child,
                ),
                if (actionButton != null)
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [actionButton],
                  ),
              ],
            ),
          ),
        );
}
