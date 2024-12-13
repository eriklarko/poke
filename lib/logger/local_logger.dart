import 'dart:async';

import 'package:logger/logger.dart';
import 'package:poke/logger/poke_logger.dart';

class LocalLogger extends PokeLogger {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      // Skip the frames coming from this logger
      stackTraceBeginIndex: 2,
      methodCount: 4,
    ),
  );

  @override
  FutureOr<void> logAppForegrounded() {
    return _log(Level.info, "app foregrounded");
  }

  @override
  FutureOr<void> trace(String msg, {Map<String, dynamic>? data}) {
    return _log(Level.trace, msg, data: data);
  }

  @override
  FutureOr<void> debug(String msg, {Map<String, dynamic>? data}) {
    return _log(Level.debug, msg, data: data);
  }

  @override
  FutureOr<void> info(String msg, {Map<String, dynamic>? data}) {
    return _log(Level.info, msg, data: data);
  }

  @override
  FutureOr<void> warn(String msg, {Map<String, dynamic>? data}) {
    return _log(Level.warning, msg, data: data);
  }

  @override
  FutureOr<void> error(
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(
      Level.error,
      msg,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  FutureOr<void> fatal(
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(
      Level.fatal,
      msg,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  FutureOr<void> log(
    Level level,
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // We configure the log printer to skip the first three frames in the stack
    // trace to make the `Logger.LEVEL(...)` calls show a more usable trace. To
    // not skip important frames if calling `Logger.log(Level...)` we must call
    // another method here.
    return _log(
      level,
      msg,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  FutureOr<void> _log(
    Level level,
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dynamic logMessage = msg;
    if (data != null) {
      data['__msg'] = msg;
      logMessage = data;
    }

    _logger.log(
      level,
      logMessage,
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }
}
