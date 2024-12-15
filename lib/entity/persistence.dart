import 'dart:async';

import 'package:poke/entity/action.dart';
import 'package:poke/entity/entity.dart';
import 'package:poke/entity/event.dart';

class Persistence {
  final Map<String, String> _entities = {};
  final Map<String, String> _actions = {};
  final Map<String, String> _events = {};

  FutureOr<void> createEntity(Entity entity) {
    // Create entity in database
  }

  FutureOr<Entity?> fetchEntity(String name) {
    return null;
  }

  ///

  FutureOr<void> createAction(Action action) {
    // Create entity in database
  }

  FutureOr<Action?> fetchAction(String name) {
    return null;
  }

  ///

  FutureOr<void> createEvent(Event event) {
    // Create entity in database
    final String eventJson = ""; //event.toJson();
    _events[event.id] = eventJson;
  }

  FutureOr<Event?> fetchEvent(String name) {
    return null;
  }
}
