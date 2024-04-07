import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide Persistence;
import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/firebase_firestore_persistence.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/screens/loading/poke_firebase.dart';
import 'package:poke/utils/key_factory.dart';
import '../utils/clock.dart';
import '../utils/test-action/test_action.dart';
import 'persistence_test.mocks.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';

final Iterable<Persistence Function()> persistenceConstructors = [
  () => InMemoryPersistence(),
  () {
    final mockFirebase = MockPokeFirebase();

    final mockUser = MockUser();
    when(mockUser.uid).thenReturn('123');
    final mockAuth = MockFirebaseAuth();
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockFirebase.auth()).thenReturn(mockAuth);

    when(mockFirebase.firestore()).thenReturn(FakeFirebaseFirestore());

    when(mockFirebase.storage()).thenReturn(MockFirebaseStorage());

    return FirebaseFirestorePersistence(mockFirebase);
  },
];

@GenerateMocks([PokeFirebase, FirebaseAuth, User])
void main() {
  test('false positives avoided by not testing any persistence implementations',
      () {
    expect(persistenceConstructors, isNotEmpty);
  });

  registerTestActions();

  for (final persistenceConstructor in persistenceConstructors) {
    group('${persistenceConstructor().runtimeType}', () {
      test('events can be serialized and deserialized again', () async {
        final persistenceImpl = persistenceConstructor();

        final testAction = TestAction(id: 'hello');
        final ts = DateTime.parse('1963-11-26 01:02:03.456');

        // log action happened at `ts`
        await persistenceImpl.logAction(testAction, ts);

        // read all logged actions, aka events
        final events = await persistenceImpl.getAllEvents();

        expect(
          events,
          equals([
            testAction.withEvent(ts),
          ]),
        );
      });

      test("events with data can be serialized correctly", () async {
        final persistenceImpl = persistenceConstructor();

        final testAction = TestActionWithData(id: '1');
        final ts = DateTime.parse('1963-11-26 01:02:03.456');

        final data = Data('foo');
        // log action happened at `ts`
        await persistenceImpl.logAction(
          testAction,
          ts,
          eventData: data,
        );

        // read all logged actions, aka events
        final events = await persistenceImpl.getAllEvents();

        expect(
          events.first,
          equals(
            testAction.withEvent(
              ts,
              eventData: data,
            ),
          ),
        );
      });

      test('logging actions allows reading them later', () async {
        final sut = persistenceConstructor();

        final Action a1 = TestAction(id: '1');
        final Action a2 = TestAction(id: '2');
        final ts1 = DateTime.parse('1963-11-26 01:02:03.456');
        final ts2 = DateTime.parse('1989-12-06 01:02:03.456');

        await sut.logAction(a1, ts1);
        await sut.logAction(a2, ts2);

        final expected = [
          a1.withEvent(ts1),
          a2.withEvent(ts2),
        ];
        expect(
          await sut.getAllEvents(),
          equals(expected),
        );
      });

      test('does not log the same event twice', () async {
        final sut = persistenceConstructor();
        final Action a = TestAction(id: '1');

        final ts = DateTime.parse('1963-11-26 01:02:03.456');
        await sut.logAction(a, ts);
        await sut.logAction(a, ts);

        expect(
          await sut.getAllEvents(),
          equals([
            a.withEvent(ts),
          ]),
        );
      });

      test('groups events together under the action', () async {
        final persistenceImpl = persistenceConstructor();

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
        await persistenceImpl.logAction(a1, ts1);
        await persistenceImpl.logAction(a2, ts2);
        await persistenceImpl.logAction(a1, ts3);

        final expected = [
          a1.withEvents({ts1: null, ts3: null}),
          a2.withEvent(ts2),
        ];
        expect(
          await persistenceImpl.getAllEvents(),
          equals(expected),
        );
      });

      test('can add actions', () async {
        final persistenceImpl = persistenceConstructor();

        final testAction = TestAction(id: '1');
        await persistenceImpl.createAction(testAction);

        expect(
          await persistenceImpl.getAllEvents(),
          equals([testAction]),
        );
      });

      test('can update action', () async {
        final persistenceImpl = persistenceConstructor();

        Action.registerSubclass(
          serializationKey: TestAction.serializationKey,
          actionFromJson: TestAction.fromJson,
          newInstanceBuilder: (_, __) => Container(),
        );

        // create an action with some properties
        final testAction = TestAction(
          id: '1',
          props: {
            'propToUpdate': '1',
            'propToRemove': '2',
            'unchanged': '3',
          },
        );
        await persistenceImpl.createAction(testAction);

        // remove prop `propToRemove`, add prop `newProp: 4` and update the action
        testAction.props!.remove('b');
        testAction.props!['c'] = '3';
        await persistenceImpl.updateAction(
          testAction.equalityKey,
          TestAction(id: testAction.id, props: {
            'propToUpdate': '11', // update from '1' to '11'
            // remove propToRemove
            'unchanged': testAction.props!['unchanged']!, // keep unchanged
            'newProp': '4', // add new prop
          }),
        );

        final actualAction = await persistenceImpl
            .getAction(testAction.equalityKey) as TestAction;
        expect(
          actualAction.props,
          equals({
            'propToUpdate': '11',
            'unchanged': '3',
            'newProp': '4',
          }),
        );
      });

      test('events are kept after updating action', () async {
        final persistenceImpl = persistenceConstructor();

        Action.registerSubclass(
          serializationKey: TestAction.serializationKey,
          actionFromJson: TestAction.fromJson,
          newInstanceBuilder: (_, __) => Container(),
        );

        // create an action
        final testAction = TestAction(
          id: '1',
          props: {
            'propToUpdate': '1',
          },
        );
        await persistenceImpl.createAction(testAction);

        // log some events so we can check that they're not lost after updating
        final dt1 = DateTime.parse('1963-11-23 13:37');
        final dt2 = DateTime.parse('1989-12-06 06:06');
        await persistenceImpl.logAction(testAction, dt1);
        await persistenceImpl.logAction(testAction, dt2);

        // update the action
        await persistenceImpl.updateAction(
          testAction.equalityKey,
          TestAction(id: testAction.id, props: {
            'propToUpdate': '11', // update from '1' to '11'
          }),
        );

        // and check that the events are still there
        final action = await persistenceImpl.getAction(testAction.equalityKey);
        expect(
          action!.events,
          equals({
            dt1: null,
            dt2: null,
          }),
        );
      });

      test('can remove events', () async {
        final persistenceImpl = persistenceConstructor();

        final Action a = TestAction(id: '1');
        final ts1 = DateTime.parse('1963-11-26 01:02:03.456');
        final ts2 = DateTime.parse('1989-12-06 01:02:03.456');

        await persistenceImpl.logAction(a, ts1);
        await persistenceImpl.logAction(a, ts2);

        await persistenceImpl.deleteEvent(a, ts2);

        final expected = [TestAction(id: '1').withEvent(ts1)];
        expect(
          await persistenceImpl.getAllEvents(),
          equals(expected),
        );
      });

      test('can fetch single action', () async {
        final persistenceImpl = persistenceConstructor();

        final Action a1 = TestAction(id: '1');
        final Action a2 = TestAction(id: '2');

        await persistenceImpl.createAction(a1);
        await persistenceImpl.createAction(a2);

        expect(
          await persistenceImpl.getAction(a1.equalityKey),
          equals(a1),
        );
      });

      test('getAction returns null if no action is found', () async {
        final persistenceImpl = persistenceConstructor();
        final Action a = TestAction(id: '1');
        await persistenceImpl.createAction(a);

        expect(
          await persistenceImpl.getAction('2'),
          equals(null),
        );
      });

      test('uploadData allows retrieving it later', () async {
        final persistenceImpl = persistenceConstructor();

        final bytes = Uint8List.fromList([1, 3, 3, 7]);
        const storageKey = 'foo';
        await persistenceImpl.uploadData(bytes, storageKey);

        expect(
          await persistenceImpl.getUploadedData(storageKey),
          equals(bytes),
        );
      });

      group('notification stream', () {
        test('sends events when a new action is added', () async {
          final persistenceImpl = persistenceConstructor();
          final testAction = TestAction(id: '1');

          // tell the key factory to return the same global key each time
          KeyFactory.setGlobalKey(GlobalKey());

          // when testing broadcast streams the `expect` call must come before
          // the events are emitted. If we `expect` after the events are emitted
          // we're too late, the events are already gone
          final updatingEvent = Updating(testAction.equalityKey);
          expectLater(
            persistenceImpl.getNotificationStream(),
            emitsInOrder([
              updatingEvent,
              FinishedUpdating(updatingEvent),
            ]),
          );

          await persistenceImpl.createAction(testAction);
        });

        test('sends events when a new log is added', () async {
          final persistenceImpl = persistenceConstructor();
          final Action testAction = TestAction(id: '1');
          final DateTime ts = DateTime.parse('1963-11-26 01:02:03.456');

          KeyFactory.setGlobalKey(GlobalKey());

          await persistenceImpl.createAction(testAction);

          final updatingEvent = Updating(testAction.equalityKey);
          expectLater(
            persistenceImpl.getNotificationStream(),
            emitsInOrder([
              updatingEvent,
              FinishedUpdating(updatingEvent),
            ]),
          );
          await persistenceImpl.logAction(testAction, ts);
        });

        test('sends events when a log is added to a nonexisting action',
            () async {
          final persistenceImpl = persistenceConstructor();
          final testAction = TestAction(id: '1');
          final ts = DateTime.parse('1963-11-26 01:02:03.456');

          KeyFactory.setGlobalKey(GlobalKey());

          final updatingEvent = Updating(testAction.equalityKey);
          expectLater(
            persistenceImpl.getNotificationStream(),
            emitsInOrder([
              updatingEvent,
              FinishedUpdating(updatingEvent),
            ]),
          );

          await persistenceImpl.logAction(testAction, ts);
        });

        test('sends events when a log is deleted', () async {
          final persistenceImpl = persistenceConstructor();

          final Action testAction = TestAction(id: '1');
          final ts = DateTime.parse('1963-11-26 01:02:03.456');

          KeyFactory.setGlobalKey(GlobalKey());

          await persistenceImpl.createAction(testAction);
          await persistenceImpl.logAction(testAction, ts);

          final updatingEvent = Updating(testAction.equalityKey);
          expectLater(
            persistenceImpl.getNotificationStream(),
            emitsInOrder([
              updatingEvent,
              FinishedUpdating(updatingEvent),
            ]),
          );

          await persistenceImpl.deleteEvent(testAction, ts);
        });
      });
    }); // end group
  }
}
