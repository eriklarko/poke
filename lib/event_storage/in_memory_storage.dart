import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/event.dart';

class InMemoryStorage implements EventStorage {
  // naming stuff is serious okay
  final Set<Event> jiggers = {};

  @override
  Future<void> addEvent(Event e) {
    jiggers.add(e);
    return Future.value(null);
  }

  @override
  Future<Set<Event>> getAll() {
    return Future.value(jiggers);
  }
}
