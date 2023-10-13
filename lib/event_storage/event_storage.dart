import 'package:poke/models/action.dart';
import 'package:poke/models/event.dart';

abstract class EventStorage {
  Future<void> logAction(Action a, DateTime when);

  Future<Set<Event>> getAll();
}
