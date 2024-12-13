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
  Future doLog(
    Level level,
    PokeLogEntry log,
  ) {
    if (!levels.contains(level)) {
      return Future.value(null);
    }

    if (log.error == null) {
      return firebase.crashlytics().log(log.toString());
    } else {
      return firebase.crashlytics().recordError(
            log.error!,
            log.stackTrace,
            reason: log.message,
            information: log.data?.entries as Iterable<Object>,
          );
    }
  }
}
