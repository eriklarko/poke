import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:poke/components/expandable-floating-action-button/expandable-floating-action-button.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/models/action.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/predictor/predictor.dart';
import 'package:poke/screens/home_screen.dart';

import '../utils/persistence.dart';
import '../utils/test-action/test_action.dart';
import 'home_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Persistence>(), MockSpec<Predictor>()])
void main() {
  setDependency<Predictor>(MockPredictor());

  testWidgets("tapping a reminder opens the log widget", (tester) async {
    final a = TestAction(id: 'some-action');
    final persistence = InMemoryPersistence();
    persistence.createAction(a);
    setPersistence(persistence);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(a.getKey('reminder-list-item')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(a.getKey('log-action')),
      findsOneWidget,
    );
  });

  testWidgets("can add new action", (tester) async {
    setPersistence(InMemoryPersistence());

    final newAction = TestAction(id: 'new-action');
    Action.registerSubclass(
      serializationKey: TestAction.serializationKey,
      type: TestAction,
      actionFromJson: TestAction.fromJson,
      newInstanceBuilder: (context, persistence) {
        return PokeButton.primary(
          onPressed: () {
            persistence.createAction(newAction);
          },
          key: const Key('add-new-test-action'),
          text: "foo",
        );
      },
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // click floating action button to bring up buttons for creating new actions
    await tester.tap(find.widgetWithIcon(ExpandableFab, Icons.create));
    await tester.pumpAndSettle();

    // click the button for creating a new test action. we see this button
    // because it was registered with `Action.registerSubclass`
    await tester.tap(find.byKey(const Key('add-new-test-action')));

    expect(find.byKey(newAction.getKey('reminder-list-item')), findsOneWidget);
  });

  group('snooze', () {
    testWidgets("swiping a reminder shows snooze action", (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      fail("");
    });

    testWidgets("tapping snooze action hides reminder", (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      fail("");
    });
  });
}
