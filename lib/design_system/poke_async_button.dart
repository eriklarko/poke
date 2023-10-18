import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';

class PokeAsyncButton extends StatefulWidget {
  final String text;
  final Future Function() onPressed;

  const PokeAsyncButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<PokeAsyncButton> createState() => _PokeAsyncButtonState();
}

class _PokeAsyncButtonState extends State<PokeAsyncButton> {
  final controller = PokeAsyncWidgetController();

  @override
  Widget build(BuildContext context) {
    return PokeAsyncWidget(
      idle: PokeButton.primary(
          onPressed: () {
            controller.setLoading();

            widget.onPressed().then((_) {
              controller.setSuccessful();
            }).catchError((error) {
              controller.setIdle();

              print('Encountered error $error');
              throw error;
            });
          },
          text: widget.text),

      loading: PokeLoadingIndicator.small,

      // because of the `onPressed().catchError` implementation in `idle`, this
      // component will never tbe rendered
      error: (error) => Container(),

      controller: controller,
    );
  }
}
