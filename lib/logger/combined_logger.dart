import 'dart:async';

import 'package:logger/logger.dart';
import 'package:poke/logger/poke_logger.dart';

// combines multiple loggers and logs to all of them
class CombinedLogger extends PokeLogger {
  final List<PokeLogger> loggers;

  CombinedLogger(this.loggers);

  @override
  FutureOr<void> logAppForegrounded() {
    return forAllLoggers((logger) => logger.logAppForegrounded());
  }

  FutureOr<Iterable<void>> combine(Iterable<FutureOr<void>> futures) {
    return Future.wait(futures.map(
      (v) => v is Future ? v : Future.value(null),
    ));
  }

  FutureOr<void> forAllLoggers(
    FutureOr<void> Function(PokeLogger) cb,
  ) {
    final Iterable<FutureOr<void>> futs = loggers.map((logger) => cb(logger));

    final allFuturesAreConstant = futs.every((fut) => fut! is Future);
    if (allFuturesAreConstant) {
      // no need to await anything
      return null;
    } else {
      // at least one of the loggers is async, so need to make this call async
      final f = Future.wait(
        futs.map(
          (v) => v is Future ? v : Future.value(null),
        ),
      );
      return f;
    }
  }

  @override
  FutureOr<void> log(
    Level level,
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return combine(
      loggers.map(
        (logger) => logger.log(
          level,
          msg,
          data: data,
          error: error,
          stackTrace: stackTrace,
        ),
      ),
    );
  }
}
