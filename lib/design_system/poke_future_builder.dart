import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';

Widget defaultError(Object error) {
  return Text(error.toString());
}

class PokeFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) child;
  final Widget loadingWidget;
  final Widget Function(Object error) error;

  const PokeFutureBuilder({
    super.key,
    required this.future,
    required this.child,
    this.loadingWidget = PokeLoadingIndicator.small,
    this.error = defaultError,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (buildContext, snapshot) {
        if (snapshot.hasData) {
          return child(snapshot.data as T);
        } else if (snapshot.hasError) {
          return error(snapshot.error!);
        } else {
          return loadingWidget;
        }
      },
    );
  }
}
