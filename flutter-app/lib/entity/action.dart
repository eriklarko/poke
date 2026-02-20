import 'package:poke/entity/event.dart';
import 'package:poke/entity/json_utils.dart';

// An action is something you do to an entity; water a plant, change the oil in
// a car, paint a house, etc.
class Action {
  final String name;
  final Iterable<Event> events;

  const Action({
    required this.name,
    this.events = const [],
  });

  String get id => name;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  factory Action.fromJson(Map<String, dynamic> json) {
    final eventsRaw = grabOptionalValue<List>(json, 'events') ?? [];

    return Action(
      name: grabRequiredValue<String>(json, 'name'),
      events: eventsRaw.map((e) => Event.fromJson(e)),
    );
  }
}
