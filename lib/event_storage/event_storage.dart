import 'package:poke/event_storage/action_with_events.dart';
import 'package:poke/event_storage/serializable_event_data.dart';
import 'package:poke/models/action.dart';

abstract class EventStorage {
  // This method head is impossible to read, but what it's saying is:
  //   method name: logAction
  //   return type: Future<void>
  //   parameters<T, S>: (S action, DateTime when, {T eventData})
  //    and here is where it gets messy; I want to disallow
  //      `logAction(WaterPlantAction(...), now(), ReplaceACFilterEventData(...))
  //    which I'm able to do by making sure that the action is of type `Action<T>`
  //    and the event data is of type T
  Future<void> logAction<TEventData extends SerializableEventData?,
      TAction extends Action<TEventData>>(
    TAction action,
    DateTime when, {
    TEventData eventData,
  });

  Future<Iterable<ActionWithEvents>> getAll();
}
