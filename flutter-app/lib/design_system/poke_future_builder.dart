import 'dart:async';

import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/logger/poke_logger.dart';

Widget defaultError(Object error, FutureOr fut) {
  // TODO: Why do I need this?
  if (fut is Future) {
    fut.onError((error, stackTrace) {
      PokeLogger.instance().error(
        'PokeFutureBuild caught unhandeled error',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }
  PokeLogger.instance().error(
    'PokeFutureBuild caught unhandeled error',
    error: error,
  );

  return Text(error.toString());
}

class PokeFutureBuilder<T> extends StatelessWidget {
  final FutureOr<T> future;
  final Widget Function(T data) child;
  final Widget loadingWidget;
  final Widget Function(Object error, FutureOr<T> future) error;

  const PokeFutureBuilder({
    super.key,
    required this.future,
    required this.child,
    this.loadingWidget = const PokeLoadingIndicator.small(),
    this.error = defaultError,
  });

  @override
  Widget build(BuildContext context) {
    final f = future;

    if (f is T) {
      // no need to render a future builder if the value is already available
      // also makes this widget easier to use with the notifications api :)
      // from https://stackoverflow.com/a/73027235
      return child(f);
    } else {
      return FutureBuilder<T>(
        future: f,
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
}
