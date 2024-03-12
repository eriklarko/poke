import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/models/action.dart';
import 'package:poke/screens/loading/firebase.dart';

class FirebaseFirestorePersistence implements Persistence {
  final PokeFirebase firebase;
  final StreamController<PersistenceEvent> notificationStreamController =
      StreamController.broadcast();

  FirebaseFirestorePersistence(this.firebase);

  @override
  Future<void> createAction(Action<SerializableEventData?> a) async {
    final updatingEvent = PersistenceEvent.updating(actionId: a.equalityKey);
    notificationStreamController.add(updatingEvent);

    final actionsRef = getActionsCollection();
    final actionRef = actionsRef.doc(a.equalityKey);

    final actionJson = a.toJson();
    await actionRef.set(actionJson, SetOptions(merge: true));

    notificationStreamController.add(PersistenceEvent.finished(updatingEvent));
  }

  @override
  Future<void> updateAction(
    String equalityKey,
    Action<SerializableEventData?> newData,
  ) async {
    final updatingEvent = PersistenceEvent.updating(actionId: equalityKey);
    notificationStreamController.add(updatingEvent);

    final actionsRef = getActionsCollection();
    final actionRef = actionsRef.doc(equalityKey);

    final existingData = await actionRef.get();
    if (!existingData.exists) {
      throw "No such action $equalityKey";
    }

    // for some reason I can't get
    //  await actionRef.set(newData.toJson(), SetOptions(mergeFields: ['events']));
    // to write the updated action data while keeping the events intact.
    await actionRef.update(newData.toJson());

    notificationStreamController.add(PersistenceEvent.finished(updatingEvent));
  }

  @override
  Future<void> logAction<TEventData extends SerializableEventData?,
          TAction extends Action<TEventData>>(TAction a, DateTime when,
      {TEventData? eventData}) async {
    final updatingEvent = PersistenceEvent.updating(actionId: a.equalityKey);
    notificationStreamController.add(updatingEvent);

    /*
     * Desired db structure
     *   /users
     *     /:userid
     *       /actions
     *         /:actionid 1
     *           - actiondata
     *           / events
     *             - { when: 1963-11-23 13:37:00, data: { ... }
     *             - { when: 1989-12-23 13:37:00, data: { ... }
     * 
     *         /water-frank
     *           / plant
     *             - id: frank
     *             - name: Frank
     *           / events
     *             - { when: yesterday,  data: { addedFertilizer: true }
     *             - { when: a year ago, data: { addedFertilizer: false }
     */

    final actionsRef = getActionsCollection();
    final actionRef = actionsRef.doc(a.equalityKey);

    final actionJson = a.toJson();
    actionJson['events'] = FieldValue.arrayUnion([
      {
        'when': when.toIso8601String(),
        'data': eventData?.toJson(),
      }
    ]);
    await actionRef.set(actionJson, SetOptions(merge: true));

    notificationStreamController.add(PersistenceEvent.finished(updatingEvent));
  }

  CollectionReference getActionsCollection() {
    final user = firebase.auth().currentUser;
    if (user == null) {
      throw "not logged in!";
    }

    return firebase
        .firestore()
        .collection('users')
        .doc(user.uid)
        .collection('actions');
  }

  @override
  Future<ActionWithEvents?> getAction(String equalityKey) async {
    final docSnapshot = await getActionsCollection().doc(equalityKey).get();
    if (docSnapshot.data() == null) {
      return null;
    }
    return parseAction(docSnapshot);
  }

  ActionWithEvents parseAction(DocumentSnapshot<Object?> doc) {
    final actionJson = doc.data();
    if (actionJson is! Map) {
      throw "data at ${doc.reference.path} is malformed; expected Map<String, dynamic>, got ${actionJson.runtimeType}";
    }

    final action = Action.fromJson(Map<String, dynamic>.from(actionJson));
    final events = parseEvents(
      actionJson['events'],
      action.runtimeType,
      doc.reference.path,
    );

    if (events == null) {
      return ActionWithEvents(action);
    } else {
      return ActionWithEvents.multiple(action, events);
    }
  }

  Map<DateTime, SerializableEventData?>? parseEvents(
    dynamic eventsJson,
    Type actionType,

    // used to tell the caller the path to the data if it is malformed in any way.
    String refPath,
  ) {
    if (eventsJson == null) {
      // not all actions have events yet
      return null;
    }
    if (eventsJson is! Iterable) {
      throw "event data at $refPath is malformed; expected a list of {when: string, data: Object}, got ${eventsJson.runtimeType}";
    }

    final Map<DateTime, SerializableEventData?> events = {};
    for (final eventMap in eventsJson) {
      if (eventMap is! Map) {
        throw "";
      }

      if (!eventMap.containsKey('when')) {
        throw "";
      }

      final when = DateTime.parse(eventMap['when']);
      final SerializableEventData? eventData = Action.eventDataFromJson(
        actionType: actionType,
        json: eventMap['data'],
      );

      events[when] = eventData;
    }
    return events;
  }

  @override
  Future<Iterable<ActionWithEvents>> getAllEvents() async {
    final List<ActionWithEvents> l = [];
    await getActionsCollection().get().then((value) {
      for (final doc in value.docs) {
        final awe = parseAction(doc);
        l.add(awe);
      }
    });

    return l;
  }

  @override
  Future<void> deleteEvent(Action a, DateTime eventDate) async {
    final updatingEvent = PersistenceEvent.updating(actionId: a.equalityKey);
    notificationStreamController.add(updatingEvent);

    final actionRef = getActionsCollection().doc(a.equalityKey);
    final actionSnap = await actionRef.get();

    // get all events as a list
    final List events = actionSnap.get('events');

    // with the list of events, find the one we want to remove
    final event = events.where((element) {
      return element["when"] == eventDate.toIso8601String();
    }).toList();

    // and remove the event by updating the events array with the
    // FieldValue.arrayRemove directive
    await actionRef.update({"events": FieldValue.arrayRemove(event)});

    notificationStreamController.add(PersistenceEvent.finished(updatingEvent));
  }

  @override
  Stream<PersistenceEvent> getNotificationStream() {
    return notificationStreamController.stream;
  }
}
