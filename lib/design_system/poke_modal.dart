import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';

class PokeModal extends Dialog {
  PokeModal({super.key, required child, PokeButton? actionButton})
      : super(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (actionButton != null)
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [actionButton],
                  ),
                if (actionButton != null) PokeConstants.FixedSpacer(),
                SingleChildScrollView(
                  child: child,
                ),
              ],
            ),
          ),
        );
}
