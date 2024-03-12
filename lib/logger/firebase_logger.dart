import 'package:logger/logger.dart';
import 'package:poke/logger/local_logger.dart';
import 'package:poke/screens/loading/poke_firebase.dart';

class FirebaseLogger extends LocalLogger {
  final PokeFirebase firebase;

  FirebaseLogger(this.firebase);

  @override
  Future logAppForegrounded() {
    return firebase.analytics().logAppOpen();
  }

  @override
  Future log(
    Level level,
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    super.log(
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
