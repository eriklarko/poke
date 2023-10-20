import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';

class InMemoryStorage implements EventStorage {
  // naming stuff is serious okay
  final Map<Action, Set<DateTime>> jiggers = {};

  @override
  Future<void> logAction(Action a, DateTime when) {
    jiggers.update(
      a,
      (dts) {
        dts.add(when);
        return dts;
      },
      ifAbsent: () => {when},
    );

    return Future.value(null);
  }

  @override
  Future<Map<Action, Set<DateTime>>> getAll() {
    return Future.value(jiggers);
  }
}
