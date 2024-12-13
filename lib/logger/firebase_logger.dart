import 'package:logger/logger.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/screens/loading/poke_firebase.dart';

class FirebaseLogger extends PokeLogger {
  final PokeFirebase firebase;
  final Iterable<Level> levels;

  FirebaseLogger(
    this.firebase, {
    this.levels = const [Level.warning, Level.error, Level.fatal],
  });

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
    if (!levels.contains(level)) {
      return Future.value(null);
    }

    final d = Map<String, Object>.from(data ?? {});
    d['__level'] = level.toString();
    d['__msg'] = msg;

    if (error != null) {
      d['__error'] = error;
    }

    if (stackTrace != null) {
      d['__stackTrace'] = stackTrace;
    }

    return firebase.crashlytics().log(d.toString());
  }
}
