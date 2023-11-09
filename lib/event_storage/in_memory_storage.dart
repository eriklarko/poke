import 'package:poke/event_storage/action_with_events.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/event_storage/serializable_event_data.dart';
import 'package:poke/models/action.dart';

class InMemoryStorage implements EventStorage {
  // naming stuff is serious okay
  final Map<Action, ActionWithEvents> jiggers = {};

  @override
  Future<void> logAction<TEventData extends SerializableEventData?,
          TAction extends Action<TEventData>>(TAction a, DateTime when,
      {TEventData? eventData}) {
    jiggers.update(
      a,
      (dts) => dts.add(when, eventData: eventData),
      ifAbsent: () => ActionWithEvents.single(a, when, data: eventData),
    );

    return Future.value(null);
  }

  @override
  Future<Iterable<ActionWithEvents>> getAll() {
    return Future.value(jiggers.values);
  }
}
