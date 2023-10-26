import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/screens/loading/firebase.dart';

class FirebaseRealtimeDBStorage implements EventStorage {
  final PokeFirebase firebase;

  FirebaseRealtimeDBStorage(this.firebase);

  @override
  Future<void> logAction(Action a, DateTime when) async {
    /*
    * From https://firebase.google.com/docs/database/flutter/lists-of-data#reading_and_writing_lists
    *
    *   Append to a list of data
    *  
    *   Use the push() method to append data to a list in multiuser applications.
    *   The push() method generates a unique key every time a new child is added
    *   to the specified Firebase reference. By using these auto-generated keys
    *   for each new element in the list, several clients can add children to the
    *   same location at the same time without write conflicts. The unique key
    *   generated by push() is based on a timestamp, so list items are
    *   automatically ordered chronologically.
    *  
    *   You can use the reference to the new data returned by the push() method to
    *   get the value of the child's auto-generated key or set data for the child.
    *   The .key property of a push() reference contains the auto-generated key.
    * 
    *   You can use these auto-generated keys to simplify flattening your data
    *   structure. For more information, see the data fan-out example.
    *   
    *   For example, push() could be used to add a new post to a list of posts in a social application:
    *     DatabaseReference postListRef = FirebaseDatabase.instance.ref("posts");
    *     DatabaseReference newPostRef = postListRef.push( *
    *       newPostRef.set({
    *       // ...
    *     });
    */

    /*
     * Desired db structure
     *   /events
     *     /:userid
     *       /:actionid 1
     *         - when 1
     *         - when 2
     *       /:actionid 2
     *         - when 1
     *         - when 2
     * 
     *   /actions
     *     /:userid
     *       /water-frank-false
     *         /plant
     *           - id: frank
     *           - name: Frank
     *         - addedFertilizer: false
     */

    // ensure action exists
    final actionRef = getActionsRef().child(a.equalityKey);
    final actionExists = await checkIfRefExists(actionRef);
    print('actionExists: $actionExists');
    if (!actionExists) {
      print("Adding action");
      await actionRef.set(a.toJson());
    }

    // write `when` to `/events/$uid/$actionId`
    final ref = getEventsRef().child(a.equalityKey);
    final newEventRef = ref.push();
    await newEventRef.set(when.toIso8601String());
    print("wrote when");
  }

  Future<bool> checkIfRefExists(DatabaseReference ref) async {
    // Get reference to Firestore collection
    final snapshot = await ref.get();
    return snapshot.exists;
  }

  DatabaseReference getActionsRef() {
    return getUserRef('actions');
  }

  DatabaseReference getUserRef(String parent) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw "not logged in!";
    }

    final String path = "$parent/${user.uid}";
    return firebase.realtimedb().ref(path);
  }

  DatabaseReference getEventsRef() {
    return getUserRef('events');
  }

  @override
  Future<Map<Action, Set<DateTime>>> getAll() async {
    // read events ref
    final ref = getEventsRef();
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      print("No data found at ${ref.path}");
      return {};
    }

    // snapshot.value is {
    //   actionEqualityKey1: [{firebaseId: some-date},{firebaseId: some-date}]},
    //   actionEqualityKey2: [{firebaseId: some-date}]},
    // }
    final value = snapshot.value;
    if (value is! Map) {
      throw "snapshot value is not a map, it's a ${snapshot.value.runtimeType}";
    }

    final Map<Action, Set<DateTime>> events = {};
    for (final a in value.entries) {
      final actionEqualityKey = a.key;
      final eventsMap = a.value;

      if (eventsMap == null) {
        print('SKIPPING $eventsMap');
        continue;
      }

      if (eventsMap is! Map) {
        throw "Expected Firebase list like Map<someFirebaseGeneratedId, String>, was $eventsMap";
      }

      // this code could be made more tolerant by logging errors and proceeding
      // instead of crashing :)
      final eventDates = eventsMap.values.map((e) => DateTime.parse(e));

      final actionMap =
          (await getActionsRef().child(actionEqualityKey).get()).value;

      if (actionMap is! Map) {
        throw "Expected json object, was $actionMap";
      }
      final action = Action.fromJson(
        // gotta do some weird ass type shit here... JSON in flutter is fudged
        Map<String, dynamic>.from(actionMap),
      );
      print("action: $action");
      events[action] = Set.from(eventDates);
    }
    return events;
  }

  @override
  Stream<(Action, Set<DateTime>)> streamAll() {
    // TODO: implement streamAll
    throw UnimplementedError();
  }
}
