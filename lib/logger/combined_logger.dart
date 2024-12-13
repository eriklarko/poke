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

  @override
  FutureOr<void> doLog(Level level, PokeLogEntry log) {
    return forAllLoggers((logger) => logger.doLog(level, log));
  }

  FutureOr<void> forAllLoggers(
    FutureOr<void> Function(PokeLogger) cb,
  ) {
    final Iterable<FutureOr<void>> futs = loggers.map((logger) => cb(logger));

    final hasAsyncLogger = futs.any((fut) => fut is Future);
    if (hasAsyncLogger) {
      // at least one of the loggers is async, so need to make this call async
      final f = Future.wait(
        futs.map(
          (v) => v is Future ? v : Future.value(null),
        ),
      );
      return f;
    } else {
      // no need to await anything
      return null;
    }
  }
}
