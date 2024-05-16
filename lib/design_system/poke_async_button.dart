import 'package:flutter/material.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';

class PokeAsyncButton extends StatefulWidget {
  final String text;
  final bool rerunnable;
  final Future Function()? onPressed;
  final bool usePrimaryButton;

  const PokeAsyncButton.once({
    super.key,
    required this.text,
    required this.onPressed,
    this.usePrimaryButton = true,
  }) : rerunnable = false;

  const PokeAsyncButton.rerunnable({
    super.key,
    required this.text,
    required this.onPressed,
    this.usePrimaryButton = true,
  }) : rerunnable = true;

  @override
  State<PokeAsyncButton> createState() => _PokeAsyncButtonState();
}

class _PokeAsyncButtonState extends State<PokeAsyncButton> {
  final controller = PokeAsyncWidgetController();

  @override
  Widget build(BuildContext context) {
    final buttonConstructor =
        widget.usePrimaryButton ? PokeButton.primary : PokeButton.small;
    return PokeAsyncWidget.simple(
      controller: controller,

      idle: buttonConstructor(
        onPressed: widget.onPressed == null
            ? null
            : () {
                controller.setLoading();

                widget.onPressed!.call().then((_) {
                  controller.setSuccessful();
                }).catchError((error) {
                  controller.setErrored(error);

                  PokeLogger.instance().error(
                    'Async button encountered error',
                    data: {'btn-text': widget.text},
                    error: error,
                  );
                });
              },
        text: widget.text,
      ),

      loading: const PokeLoadingIndicator.small(),

      error: (error) => PokeText(error.toString()),

      // once the button's action has been executed we can either show the idle
      // state again, or show a success indicator.
      // for buttons that should execute their action only once we don't want to
      // show the button again once the action is completed, so we specify a
      // `success` widget here
      success: widget.rerunnable ? null : PokeText('success!'),
    );
  }
}
