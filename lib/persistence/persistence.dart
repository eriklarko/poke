import 'dart:typed_data';

import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/persistence/serializable_event_data.dart';

abstract class Persistence {
  Future<void> logAction<TEventData extends SerializableEventData?>(
    Action<TEventData> action,
    DateTime when, {
    TEventData? eventData,
  });

  Future<Action?> getAction(String equalityKey);

  Future<Iterable<Action>> getAllActions();

  Future<void> createAction(Action action);

  Future<void> updateAction(String equalityKey, Action action);

  Future<void> deleteEvent(Action a, DateTime eventDate);

  Stream<PersistenceEvent> getNotificationStream();

  Future<Uri> uploadData(Uint8List bytes, String storageKey);

  Future<Uint8List?> getUploadedData(String storageKey);
}
