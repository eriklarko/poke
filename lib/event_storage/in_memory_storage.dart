import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/event.dart';

class InMemoryStorage implements EventStorage {
  // naming stuff is serious okay
  final Set<Event> jiggers = {};

  @override
  Future<void> logAction(Action a, DateTime when) {
    jiggers.add(Event(action: a, when: when));
    return Future(() => null);
  }

  @override
  Future<Set<Event>> getAll() {
    return Future.value(jiggers);
  }
}
