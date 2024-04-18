import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/screens/loading/poke_firebase.dart';

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

    final existingData = await getAction(equalityKey);
    if (existingData == null) {
      throw "No such action $equalityKey";
    }

    final actionsRef = getActionsCollection();
    final actionRef = actionsRef.doc(equalityKey);

    // for some reason I can't get
    //  await actionRef.set(newData.toJson(), SetOptions(mergeFields: ['events']));
    // to write the updated action data while keeping the events intact.
    newData.events.addAll(existingData.events);
    await actionRef.update(newData.toJson());

    notificationStreamController.add(PersistenceEvent.finished(updatingEvent));
  }

  @override
  Future<void> logAction<TEventData extends SerializableEventData?>(
    Action<TEventData> action,
    DateTime when, {
    TEventData? eventData,
  }) async {
    final updatingEvent =
        PersistenceEvent.updating(actionId: action.equalityKey);
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
    final actionRef = actionsRef.doc(action.equalityKey);

    final actionJson = action.toJson();
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
  Future<Action?> getAction(String equalityKey) async {
    final docSnapshot = await getActionsCollection().doc(equalityKey).get();
    if (docSnapshot.data() == null) {
      return null;
    }
    return parseAction(docSnapshot);
  }

  Action parseAction(DocumentSnapshot<Object?> doc) {
    final actionJson = doc.data();
    if (actionJson is! Map) {
      throw "data at ${doc.reference.path} is malformed; expected Map<String, dynamic>, got ${actionJson.runtimeType}";
    }

    if (actionJson['events'] is List) {
      actionJson['events'] = _firebaseMapToFlutterMap<String, dynamic>(
        actionJson['events'],
        "${doc.reference.path}/events",
      );
    }

    return Action.fromJson(Map<String, dynamic>.from(actionJson));
  }

  // Firebase maps are lists with map entries in them, so we need to convert
  // them to flutter maps
  //  [
  //    {key: "some-key-1", value: "some-value-1"},
  //    {key: "some-key-2", value: "some-value-2"},
  //  ] => {
  //    "some-key-1": "some-value-1",
  //    "some-key-2": "some-value-2",
  //  }
  Map<TKey, TValue> _firebaseMapToFlutterMap<TKey, TValue>(
    List<dynamic> firebaseMap,
    // used to tell the user where malformed data is located in case of failure
    String referencePath,
  ) {
    final m = <TKey, TValue>{};
    for (final mapEntry in firebaseMap) {
      if (mapEntry is! Map) {
        throw "data at $referencePath is malformed; expected Map<String, dynamic>, got ${mapEntry.runtimeType}";
      }

      // `mapEntry` is a map with two keys, "when" and "data". These strings are
      // set by the `logAction` function above.
      // {
      //    "when": "1963-11-26 01:02:03",
      //    "data": "some-data",
      // } =>
      // m["1963-11-26 01:02:03"] = "some-data"
      m[mapEntry["when"]] = mapEntry["data"];
    }
    return m;
  }

  @override
  Future<Iterable<Action>> getAllActions() async {
    final List<Action> l = [];
    await getActionsCollection().get().then((value) {
      for (final doc in value.docs) {
        final a = parseAction(doc);
        l.add(a);
      }
    });

    return l;
  }

  @override
  Future<void> deleteEvent(Action a, DateTime eventDate) async {
    final updatingEvent = PersistenceEvent.updating(actionId: a.equalityKey);
    notificationStreamController.add(updatingEvent);

    // get all events as a list
    final actionRef = getActionsCollection().doc(a.equalityKey);
    final actionSnap = await actionRef.get();
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

  @override
  Future<Uri> uploadData(
    Uint8List bytes,
    String storageKey,
  ) async {
    final user = firebase.auth().currentUser;
    if (user == null) {
      throw "not logged in!";
    }

    final storageRef = firebase.storage().ref();
    final spaceRef = storageRef.child(
      "/users/${user.uid}/$storageKey",
    );

    await spaceRef.putData(bytes);
    final downloadUrl = await spaceRef.getDownloadURL();
    return Uri.parse(downloadUrl);
  }

  @override
  Future<Uint8List?> getUploadedData(String storageKey) {
    final user = firebase.auth().currentUser;
    if (user == null) {
      throw "not logged in!";
    }

    final storageRef = firebase.storage().ref();
    final spaceRef = storageRef.child(
      "/users/${user.uid}/$storageKey",
    );

    return spaceRef.getData();
  }
}
