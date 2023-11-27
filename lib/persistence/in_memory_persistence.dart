import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/models/action.dart';

class InMemoryPersistence implements Persistence {
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
  Future<Iterable<ActionWithEvents>> getAllEvents() {
    return Future.value(jiggers.values);
  }

  @override
  Future<void> createAction(Action<SerializableEventData?> action) {
    jiggers[action] = ActionWithEvents(action);
    return Future.value(null);
  }
}
