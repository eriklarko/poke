import 'package:flutter/material.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';

typedef OnPressed = Future Function();
typedef ButtonConstructor = PokeButton Function({
  Key? key,
  required String text,
  required Function()? onPressed,
});

class PokeAsyncButton<TError> extends StatefulWidget {
  final String text;
  final bool rerunnable;
  final bool retryable;
  final OnPressed? onPressed;
  final ButtonConstructor buttonConstructor;

  final Widget Function(TError)? error;

  const PokeAsyncButton.once({
    super.key,
    required this.text,
    required this.onPressed,
    this.error,
    this.buttonConstructor = PokeButton.primary,
  })  : rerunnable = false,
        retryable = false;

  const PokeAsyncButton.rerunnable({
    super.key,
    required this.text,
    required this.onPressed,
    this.error,
    this.buttonConstructor = PokeButton.primary,
  })  : rerunnable = true,
        retryable = false;

  const PokeAsyncButton.primaryDangerous({
    super.key,
    required this.text,
    required this.onPressed,
    this.error,
    this.buttonConstructor = PokeButton.primaryDangerous,
  })  : rerunnable = false,
        retryable = false;

  factory PokeAsyncButton.icon({
    Key? key,
    required IconData icon,
    required OnPressed? onPressed,
    IconData errorIcon = Icons.error,
    double? iconSize,
    bool rerunnable = true,
  }) {
    final ctor = rerunnable ? PokeAsyncButton.rerunnable : PokeAsyncButton.once;
    return ctor(
      key: key,
      text: '',
      onPressed: onPressed,
      error: (_) => Icon(errorIcon),
      buttonConstructor: ({key, required onPressed, required text}) {
        return PokeButton.icon(
          icon,
          key: key,
          onPressed: onPressed,
          iconSize: iconSize,
        );
      },
    );
  }

  @override
  State<PokeAsyncButton<TError>> createState() =>
      _PokeAsyncButtonState<TError>();
}

class _PokeAsyncButtonState<TError> extends State<PokeAsyncButton<TError>> {
  final controller = PokeAsyncWidgetController<TError>();

  @override
  Widget build(BuildContext context) {
    return PokeAsyncWidget.simple(
      controller: controller,

      idle: widget.buttonConstructor(
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
                    data: {'key': widget.key, 'btn-text': widget.text},
                    error: error,
                  );
                });
              },
        text: widget.text,
      ),

      loading: const PokeLoadingIndicator.small(),

      error: (error) {
        if (widget.retryable) {
          controller.setIdle();
        } else if (widget.error != null) {
          return widget.error!(error);
        }

        return PokeText(error.toString());
      },

      // once the button's action has been executed we can either show the idle
      // state again, or show a success indicator.
      // for buttons that should execute their action only once we don't want to
      // show the button again once the action is completed, so we specify a
      // `success` widget here
      success: widget.rerunnable ? null : PokeText('success!'),
    );
  }
}
