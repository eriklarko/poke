import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/logger/poke_logger.dart';

Widget defaultError(Object error, Future fut) {
  fut.onError((error, stackTrace) {
    PokeLogger.instance().error(
      'PokeFutureBuild caught unhandeled error',
      error: error,
      stackTrace: stackTrace,
    );
  });
  return Text(error.toString());
}

class PokeFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) child;
  final Widget loadingWidget;
  final Widget Function(Object error, Future<T> future) error;

  const PokeFutureBuilder({
    super.key,
    required this.future,
    required this.child,
    this.loadingWidget = const PokeLoadingIndicator.small(),
    this.error = defaultError,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (buildContext, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return error(snapshot.error!, future);
          } else {
            return child(snapshot.data as T);
          }
        }

        return loadingWidget;
      },
    );
  }
}
