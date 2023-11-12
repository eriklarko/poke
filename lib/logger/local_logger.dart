import 'package:logger/logger.dart';
import 'package:poke/logger/poke_logger.dart';

class LocalLogger implements PokeLogger {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      // Skip the frames coming from this logger
      stackTraceBeginIndex: 2,
      methodCount: 4,
    ),
  );

  @override
  Future logAppForegrounded() {
    return _log(Level.info, "app foregrounded");
  }

  @override
  Future trace(String msg, {Map<String, dynamic>? data}) {
    return _log(Level.trace, msg, data: data);
  }

  @override
  Future debug(String msg, {Map<String, dynamic>? data}) {
    return _log(Level.debug, msg, data: data);
  }

  @override
  Future info(String msg, {Map<String, dynamic>? data}) {
    return _log(Level.info, msg, data: data);
  }

  @override
  Future warn(String msg, {Map<String, dynamic>? data}) {
    return _log(Level.warning, msg, data: data);
  }

  @override
  Future error(
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(Level.error, msg,
        data: data, error: error, stackTrace: stackTrace);
  }

  @override
  Future fatal(
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(Level.fatal, msg,
        data: data, error: error, stackTrace: stackTrace);
  }

  @override
  Future log(
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

  Future _log(
    Level level,
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) async {
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
