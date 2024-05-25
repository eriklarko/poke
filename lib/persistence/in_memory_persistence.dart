import 'dart:async';
import 'dart:typed_data';

import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/persistence/serializable_event_data.dart';

class InMemoryPersistence implements Persistence {
  // naming stuff is serious okay
  final Map<String, Action> jiggers = {};

  final Map<Uri, Uint8List> uploadedData = {};

  final StreamController<PersistenceEvent> notificationStreamController =
      StreamController.broadcast();

  @override
  Future<void> logAction<TEventData extends SerializableEventData?>(
    Action<TEventData> action,
    DateTime when, {
    TEventData? eventData,
  }) {
    final Updating u = PersistenceEvent.updating(actionId: action.equalityKey);
    emitEvent(u);

    jiggers.update(
      action.equalityKey,
      (a) => a.withEvent(when, eventData: eventData),
      ifAbsent: () => action.withEvent(
        when,
        eventData: eventData,
      ),
    );
    emitEvent(PersistenceEvent.finished(u));

    return Future.value(null);
  }

  @override
  Future<Action?> getAction(String equalityKey) {
    // Search existing actions for the one with the provided equality key.
    // I'm not using findWhere here because it throws StateError when nothing is
    // found, and I want null
    for (final action in jiggers.values) {
      if (action.equalityKey == equalityKey) {
        return Future.value(_copy(action));
      }
    }

    return Future.value(null);
  }

  Action<T> _copy<T extends SerializableEventData?>(Action<T> a) {
    final j = a.toJson();
    return Action.fromJson(j) as Action<T>;
  }

  @override
  Future<Iterable<Action>> getAllActions() {
    // Any caller could theoretically change the values in the objects returned
    // from this function; like add an event like
    //   final events = await persistence.getAllEvents();
    //   events.first.events[DateTime.now()] = ...
    //
    // to enforce the use of `persistence.logAction(...)`, this usage is
    // prevented by copying the data in this method.
    final copies = jiggers.values.map((a) => _copy(a));
    return Future.value(copies);
  }

  @override
  Future<void> createAction(Action<SerializableEventData?> action) {
    final Updating u = PersistenceEvent.updating(actionId: action.equalityKey);
    emitEvent(u);

    jiggers[action.equalityKey] = action;

    emitEvent(PersistenceEvent.finished(u));

    return Future.value(null);
  }

  @override
  Future<T> updateAction<T extends Action>(
    String equalityKey,
    T newData,
  ) async {
    final Updating u = PersistenceEvent.updating(actionId: equalityKey);
    emitEvent(u);

    final existingData = await getAction(equalityKey);
    if (existingData == null) {
      throw "unknown action $equalityKey";
    }

    jiggers.remove(existingData.equalityKey);
    jiggers[newData.equalityKey] = newData.withEvents(existingData.events);

    emitEvent(PersistenceEvent.finished(u));

    return newData;
  }

  @override
  Future<void> deleteAction(String equalityKey) {
    final Updating u = PersistenceEvent.updating(actionId: equalityKey);
    emitEvent(u);

    jiggers.removeWhere((key, value) => key == equalityKey);

    emitEvent(PersistenceEvent.finished(u));
    return Future.value(null);
  }

  @override
  Future<void> deleteEvent(
    Action<SerializableEventData?> a,
    DateTime eventDate,
  ) {
    if (!jiggers.containsKey(a.equalityKey)) {
      throw "Could not find action $a";
    }

    final Updating u = PersistenceEvent.updating(actionId: a.equalityKey);
    emitEvent(u);

    final events = jiggers[a.equalityKey]!.events;
    events.remove(eventDate);

    jiggers[a.equalityKey] = a.withEvents(events);

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

  @override
  Future<Uri> uploadData(Uint8List data, String storageKey) {
    final Uri uri = Uri.file(storageKey);
    uploadedData[uri] = data;

    return Future.value(uri);
  }

  @override
  Future<Uint8List?> getUploadedData(String storageKey) {
    final Uri uri = Uri.file(storageKey);
    return Future.value(uploadedData[uri]);
  }
}
