import 'dart:async';

import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/event_storage/action_with_events.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/screens/home_screen.dart';

import '../utils/test-action/test_action.dart';
import 'home_screen_test.mocks.dart';

final List<ActionWithEvents> noEvents = [];

@GenerateMocks([EventStorage])
void main() {
  testWidgets('renders reminders', (tester) async {
    final eventStorage = MockEventStorage();
    when(eventStorage.getAll()).thenAnswer(
      (_) => Future.value([
        ActionWithEvents.single(TestAction(id: 'some-action'), DateTime.now()),
      ]),
    );
    setEventStorage(eventStorage);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('some-action')), findsOneWidget);
  });

  testWidgets('renders a loading indicator while reminders are loading',
      (tester) async {
    final eventStorage = MockEventStorage();
    when(eventStorage.getAll()).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 2),
        () => noEvents,
      ),
    );
    setEventStorage(eventStorage);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byType(PokeLoadingIndicator), findsOneWidget);

    // finish timers to make flutter happi
    await tester.pump(const Duration(milliseconds: 1000));
  });

  testWidgets('Allows retrying when building reminders fail', (tester) async {
    final eventStorage = MockEventStorage();
    when(eventStorage.getAll()).thenAnswer(
      (_) async => noEvents,
    );
    setEventStorage(eventStorage);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // allow future to fail
    await tester.pump();

    // tap the retry button
    await tester.tap(find.byKey(const Key('retry')));

    verify(eventStorage.getAll()).called(2);
  });

  testWidgets('snoozing reminders removes them', (tester) async {
    fail('not implemented yet');
  });
}

void setEventStorage(EventStorage eventStorage) {
  GetIt.instance.allowReassignment = true;
  GetIt.instance.registerSingleton<EventStorage>(eventStorage);
}
