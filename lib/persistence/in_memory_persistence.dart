import 'dart:async';

import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/models/action.dart';

class InMemoryPersistence implements Persistence {
  // naming stuff is serious okay
  final Map<Action, ActionWithEvents> jiggers = {};

  final StreamController<PersistenceEvent> notificationStreamController =
      StreamController.broadcast();

  @override
  Future<void> logAction<TEventData extends SerializableEventData?,
          TAction extends Action<TEventData>>(TAction a, DateTime when,
      {TEventData? eventData}) {
    final Updating u = PersistenceEvent.updating(actionId: a.equalityKey);
    emitEvent(u);

    jiggers.update(
      a,
      (dts) => dts.add(when, eventData: eventData),
      ifAbsent: () {
        final awe = ActionWithEvents.single(a, when, data: eventData);
        return awe;
      },
    );
    emitEvent(PersistenceEvent.finished(u));

    return Future.value(null);
  }

  @override
  Future<ActionWithEvents> getAction(String equalityKey) {
    // Search existing actions for the one with the provided equality key.
    // I'm not using findWhere here because the StateError it returns wasn't as
    // readable as I wanted
    for (final awe in jiggers.values) {
      if (awe.action.equalityKey == equalityKey) {
        return Future.value(awe.copy());
      }
    }

    throw "No action with equality key '$equalityKey' found";
  }

  @override
  Future<Iterable<ActionWithEvents>> getAllEvents() {
    // Any caller could theoretically change the values in the objects returned
    // from this function; like add an event like
    //   final events = await persistence.getAllEvents();
    //   events.first.events[DateTime.now()] = ...
    //
    // to enforce the use of `persistence.logAction(...)`, this usage is
    // prevented by copying the data in this method.
    return Future.value(jiggers.values.map((awe) => awe.copy()));
  }

  @override
  Future<void> createAction(Action<SerializableEventData?> action) {
    final Updating u = PersistenceEvent.updating(actionId: action.equalityKey);
    emitEvent(u);

    jiggers[action] = ActionWithEvents(action);

    emitEvent(PersistenceEvent.finished(u));

    return Future.value(null);
  }

  @override
  Future<void> deleteEvent(
      Action<SerializableEventData?> a, DateTime eventDate) {
    if (!jiggers.containsKey(a)) {
      throw "Could not find action $a";
    }

    final Updating u = PersistenceEvent.updating(actionId: a.equalityKey);
    emitEvent(u);

    final events = jiggers[a]!.events;
    events.remove(eventDate);

    jiggers[a] = ActionWithEvents.multiple(a, events);

    emitEvent(PersistenceEvent.finished(u));
    return Future.value(null);
  }

  void emitEvent(PersistenceEvent e) {
    notificationStreamController.add(e);
  }

  @override
  Stream<PersistenceEvent> getNotificationStream() {
    return notificationStreamController.stream;
  }
}
