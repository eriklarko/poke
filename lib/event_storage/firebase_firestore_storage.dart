import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/screens/loading/firebase.dart';

class FirebaseFirestoreStorage implements EventStorage {
  final PokeFirebase firebase;

  FirebaseFirestoreStorage(this.firebase);

  @override
  Future<void> logAction(Action a, DateTime when) async {
    /*
     * Desired db structure
     *   /users
     *     /:userid
     *       /actions
     *         /:actionid 1
     *           - actiondata
     *           / events
     *             - when 1
     *             - when 2
     * 
     *         /water-frank-false
     *           / plant
     *             - id: frank
     *             - name: Frank
     *           - addedFertilizer: false
     *           / events
     *             - yesterday
     *             - a year ago
     */

    final actionsRef = getActionsCollection();
    final actionRef = actionsRef.doc(a.equalityKey);

    final actionJson = a.toJson();
    actionJson['when'] = FieldValue.arrayUnion([when.toIso8601String()]);
    await actionRef.set(actionJson, SetOptions(merge: true));
  }

  CollectionReference getActionsCollection() {
    final user = FirebaseAuth.instance.currentUser;
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
  Future<Map<Action, Set<DateTime>>> getAll() async {
    final Map<Action, Set<DateTime>> events = {};

    await getActionsCollection().get().then((value) {
      for (final doc in value.docs) {
        final actionJson = doc.data();
        if (actionJson is! Map) {
          throw "data at ${doc.reference.path} is malformed; expected Map<String, dynamic>, got ${actionJson.runtimeType}";
        }

        final eventStrings = actionJson['when'];
        if (eventStrings is! Iterable) {
          throw "event data at ${doc.reference.path} is malformed; expected a list of strings, got ${events.runtimeType}";
        }
        final eventDates =
            eventStrings.map((dateString) => DateTime.parse(dateString));

        final action = Action.fromJson(Map<String, dynamic>.from(actionJson));
        events[action] = Set.from(eventDates);
      }
    });

    return events;
  }

  @override
  Stream<(Action, Set<DateTime>)> streamAll() {
    // TODO: implement streamAll
    throw UnimplementedError();
  }
}
