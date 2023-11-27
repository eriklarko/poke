import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide Persistence;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/firebase_firestore_persistence.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/models/action.dart';
import 'package:poke/screens/loading/firebase.dart';
import '../utils/clock.dart';
import '../utils/test-action/test_action.dart';
import 'event_storage_test.mocks.dart';

final Iterable<Persistence Function()> eventStorageConstructors = [
  () => InMemoryPersistence(),
  () {
    final mockFirebase = MockPokeFirebase();

    final mockUser = MockUser();
    when(mockUser.uid).thenReturn('123');
    final mockAuth = MockFirebaseAuth();
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockFirebase.auth()).thenReturn(mockAuth);

    when(mockFirebase.firestore()).thenReturn(FakeFirebaseFirestore());

    return FirebaseFirestorePersistence(mockFirebase);
  },
];

@GenerateMocks([PokeFirebase, FirebaseAuth, User])
void main() {
  test('false positives avoided by not testing any event storages', () {
    expect(eventStorageConstructors, isNotEmpty);
  });

  registerTestActions();

  for (final eventStorageConstructor in eventStorageConstructors) {
    group('${eventStorageConstructor().runtimeType}', () {
      test('events can be serialized and deserialized again', () async {
        final eventStorage = eventStorageConstructor();

        final testAction = TestAction(id: 'hello');
        final ts = DateTime.parse('1963-11-26 01:02:03.456');

        // log action happened at `ts`
        await eventStorage.logAction(
          testAction,
          ts,
        );

        // read all logged actions, aka events
        final events = await eventStorage.getAllEvents();

        expect(
          events,
          equals([
            ActionWithEvents<Null, TestAction>.single(testAction, ts),
          ]),
        );
      });

      test("events with data can be serialized correctly", () async {
        final eventStorage = eventStorageConstructor();

        final testAction = TestActionWithData(id: '1');
        final ts = DateTime.parse('1963-11-26 01:02:03.456');

        final data = Data('foo');
        // log action happened at `ts`
        await eventStorage.logAction(
          testAction,
          ts,
          eventData: data,
        );

        // read all logged actions, aka events
        final events = await eventStorage.getAllEvents();

        expect(
          events.first,
          equals(
            ActionWithEvents<Data, TestActionWithData>.single(
              testAction,
              ts,
              data: data,
            ),
          ),
        );
      });

      test('logging actions allows reading them later', () async {
        final sut = eventStorageConstructor();

        final Action a1 = TestAction(id: '1');
        final Action a2 = TestAction(id: '2');
        final ts1 = DateTime.parse('1963-11-26 01:02:03.456');
        final ts2 = DateTime.parse('1989-12-06 01:02:03.456');

        await sut.logAction(a1, ts1);
        await sut.logAction(a2, ts2);

        final expected = [
          ActionWithEvents.single(a1, ts1),
          ActionWithEvents.single(a2, ts2),
        ];
        expect(
          await sut.getAllEvents(),
          equals(expected),
        );
      });

      test('does not log the same event twice', () async {
        final sut = eventStorageConstructor();
        final Action a = TestAction(id: '1');

        final ts = DateTime.parse('1963-11-26 01:02:03.456');
        await sut.logAction(a, ts);
        await sut.logAction(a, ts);

        expect(
          await sut.getAllEvents(),
          equals([
            ActionWithEvents.single(a, ts),
          ]),
        );
      });

      test('groups events together under the action', () async {
        final eventStorage = eventStorageConstructor();

        // create two different actions to be logged at different timestamps further
        // down
        final a1 = TestAction(id: '1');
        final a2 = TestAction(id: '2');

        // get references to the timestamps we're logging the actions at so that we
        // can check them later
        final clock = Clock();
        final ts1 = clock.next();
        final ts2 = clock.next();
        final ts3 = clock.next();

        // log the actions at their corresponding timestamps
        await eventStorage.logAction(a1, ts1);
        await eventStorage.logAction(a2, ts2);
        await eventStorage.logAction(a1, ts3);

        final expected = [
          ActionWithEvents.multiple(a1, {ts1: null, ts3: null}),
          ActionWithEvents.single(a2, ts2),
        ];
        expect(
          await eventStorage.getAllEvents(),
          equals(expected),
        );
      });
    }); // end group
  }
}
