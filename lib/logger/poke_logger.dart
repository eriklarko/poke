import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:poke/screens/loading/firebase.dart';

abstract interface class PokeLogger {
  Future logAppForegrounded();

  Future trace(String msg, {Map<String, dynamic>? data});
  Future debug(String msg, {Map<String, dynamic>? data});
  Future info(String msg, {Map<String, dynamic>? data});
  Future warn(String msg, {Map<String, dynamic>? data});
  Future error(
    String msg, {
    Map<String, dynamic> data,
    Object? error,
    StackTrace? stackTrace,
  });
  Future fatal(
    String msg, {
    Map<String, dynamic> data,
    Object? error,
    StackTrace? stackTrace,
  });
  Future log(
    Level level,
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  static PokeLogger instance() {
    return GetIt.instance.get<PokeLogger>();
  }
}

class FirebaseLogger implements PokeLogger {
  final PokeFirebase firebase;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      // Skip the frames coming from this logger
      stackTraceBeginIndex: 3,
      methodCount: 5,
    ),
  );

  FirebaseLogger(this.firebase);

  @override
  Future logAppForegrounded() {
    return firebase.analytics().logAppOpen();
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
  }) {
    _logLocally(
      level,
      msg,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    return _logRemotely(
      level,
      msg,
      data: data,
      error: error,
    );
  }

  void _logLocally(
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

  // ignores trace, debug and info
  Future _logRemotely(
    Level level,
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
  }) {
    switch (level) {
      case Level.warning:
      case Level.error:
      case Level.fatal:
        final d = data ?? {};
        d['__msg'] = msg;
        d['__error'] = error;

        final String event = d.remove('event') ?? 'unknown';

        return firebase
            .analytics()
            .logEvent(name: '$level - $event', parameters: d);
      default:
        return Future.value(null);
    }
  }
}
