import 'package:poke/models/action.dart';

abstract class EventStorage {
  Future<void> logAction(Action a, DateTime when);

  Future<Map<Action, Set<DateTime>>> getAll();
}
