import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/predictor/predictor.dart';
import 'package:poke/screens/home_screen.dart';

import '../utils/test-action/test_action.dart';
import 'home_screen_test.mocks.dart';

final List<ActionWithEvents> noEvents = [];

@GenerateNiceMocks([MockSpec<Persistence>(), MockSpec<Predictor>()])
void main() {
  testWidgets('renders reminders', (tester) async {
    final a = ActionWithEvents.single(
      TestAction(id: 'some-action'),
      DateTime.now(),
    );
    final persistence = MockPersistence();
    when(persistence.getAllEvents()).thenAnswer(
      (_) => Future.value([a]),
    );
    setPersistence(persistence);
    final p = MockPredictor();
    when(p.predictNext(a)).thenReturn(DateTime.now());
    GetIt.instance.registerSingleton<Predictor>(MockPredictor());

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('some-action')), findsOneWidget);
  });

  testWidgets('renders a loading indicator while reminders are loading',
      (tester) async {
    final persistence = MockPersistence();
    when(persistence.getAllEvents()).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 2),
        () => noEvents,
      ),
    );
    setPersistence(persistence);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byType(PokeLoadingIndicator), findsOneWidget);

    // finish timers to make flutter happi
    await tester.pump(const Duration(milliseconds: 1000));
  });

  testWidgets('Allows retrying when building reminders fail', (tester) async {
    final persistence = MockPersistence();
    when(persistence.getAllEvents()).thenAnswer(
      (_) async => noEvents,
    );
    setPersistence(persistence);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // allow future to fail
    await tester.pump();

    // tap the retry button
    await tester.tap(find.byKey(const Key('retry')));

    verify(persistence.getAllEvents()).called(2);
  });

  testWidgets('Snoozing reminders removes them', (tester) async {
    fail('not implemented yet');
  });

  testWidgets('Renders new action when it is added', (tester) async {
    fail("niy");
  });

  testWidgets('Rerenders when visible persistence data is changed',
      (tester) async {
    // create the action with one event being shown to the user
    final action = TestActionWithData(id: 'some-action');

    // set up the persistence system to return the action above
    final persistence = InMemoryPersistence();
    persistence.logAction(
      action,
      DateTime.now(),
      eventData: Data("first-data"),
    );
    setPersistence(persistence);

    // more deps, not really part of this test
    final p = MockPredictor();
    when(p.predictNext(any)).thenReturn(DateTime.now());
    GetIt.instance.registerSingleton<Predictor>(MockPredictor());

    // render reminders for the action
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // check that the first data is shown
    expect(find.text("first-data"), findsOneWidget);

    // add a new event to the data, rendering its data instead
    persistence.logAction(
      action,
      DateTime.now(),
      eventData: Data("second-data"),
    );
    //await pumpEventQueue(); // this hangs forever :(
    await tester.pumpAndSettle();

    // check that this second data is shown
    expect(find.text("second-data"), findsOneWidget);
  });
}

void setPersistence(Persistence persistence) {
  GetIt.instance.allowReassignment = true;
  GetIt.instance.registerSingleton<Persistence>(persistence);
}
