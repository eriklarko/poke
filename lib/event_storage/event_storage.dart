import 'package:poke/models/event.dart';

abstract class EventStorage {
  Future<void> addEvent(Event e);

  Future<Set<Event>> getAll();
}
