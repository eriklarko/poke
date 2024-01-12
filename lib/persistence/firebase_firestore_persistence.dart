import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/models/action.dart';
import 'package:poke/screens/loading/firebase.dart';

class FirebaseFirestorePersistence implements Persistence {
  final PokeFirebase firebase;

  FirebaseFirestorePersistence(this.firebase);

  @override
  Future<void> createAction(Action<SerializableEventData?> a) async {
    final actionsRef = getActionsCollection();
    final actionRef = actionsRef.doc(a.equalityKey);

    final actionJson = a.toJson();
    await actionRef.set(actionJson, SetOptions(merge: true));
  }

  @override
  Future<void> logAction<TEventData extends SerializableEventData?,
          TAction extends Action<TEventData>>(TAction a, DateTime when,
      {TEventData? eventData}) async {
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
  Future<Iterable<ActionWithEvents>> getAllEvents() async {
    final List<ActionWithEvents> l = [];
    await getActionsCollection().get().then((value) {
      for (final doc in value.docs) {
        final actionJson = doc.data();
        if (actionJson is! Map) {
          throw "data at ${doc.reference.path} is malformed; expected Map<String, dynamic>, got ${actionJson.runtimeType}";
        }

        final action = Action.fromJson(Map<String, dynamic>.from(actionJson));
        final awe = ActionWithEvents(action);
        l.add(awe);

        ////////////////////
        /// parse events ///
        final eventsList = actionJson['events'];
        if (eventsList == null) {
          // not all actions have events yet
          continue;
        }
        if (eventsList is! Iterable) {
          throw "event data at ${doc.reference.path} is malformed; expected a list of {when: string, data: Object}, got ${eventsList.runtimeType}";
        }

        for (final eventMap in eventsList) {
          if (eventMap is! Map) {
            throw "";
          }

          if (!eventMap.containsKey('when')) {
            throw "";
          }

          final when = DateTime.parse(eventMap['when']);
          final SerializableEventData? eventData = Action.eventDataFromJson(
            actionType: action.runtimeType,
            json: eventMap['data'],
          );

          awe.add(when, eventData: eventData);
        }

        /// parse events ///
        ////////////////////
      }
    });

    return l;
  }

  @override
  Future<void> deleteEvent(Action a, DateTime eventDate) async {
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
  }
}
