import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';

class PokeModal extends Dialog {
  BuildContext? _shownInContext;

  // creates a new modal showing `child`, and an optional "actionButton" at the
  // top left side of the modal.
  //
  // The modal then needs to be shown by calling `modal.show(context)`.
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

  void show(BuildContext context) {
    _shownInContext = context;

    showDialog(
      context: context,
      builder: (context) => build(context),
    );
  }

  void dismiss() {
    if (_shownInContext != null) {
      Navigator.of(_shownInContext!).pop();
    }
  }
}
