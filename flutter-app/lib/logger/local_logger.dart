import 'dart:async';

import 'package:logger/logger.dart';
import 'package:poke/logger/poke_logger.dart';

class LocalLogger extends PokeLogger {
  final Logger _logger;
  LocalLogger({
    // Skip the frames coming from this logger. If wrapping this logger in
    // another logger, you may want to skip more frames.
    stackTraceBeginIndex = 2,
    // how many methods in the stack trace to show. NOTE! The actual number of
    // methods shown will be this number - stackTraceBeginIndex.
    methodCount = 4,
  }) : _logger = Logger(
          printer: PrettyPrinter(
            stackTraceBeginIndex: stackTraceBeginIndex,
            methodCount: methodCount,
          ),
        );

  @override
  FutureOr<void> logAppForegrounded() {
    return log(Level.info, "app foregrounded");
  }

  @override
  FutureOr<void> doLog(
    Level level,
    PokeLogEntry log,
  ) {
    dynamic logMessage = log.message;
    if (log.data != null) {
      log.data!['__msg'] = log.message;
      logMessage = log.data;
    }

    _logger.log(
      level,
      logMessage,
      error: log.error,
      stackTrace: log.stackTrace ?? StackTrace.current,
    );
  }
}
