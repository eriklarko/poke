import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_permission_widget.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/reminder_service/reminder_service.dart';
import 'package:poke/screens/home_screen.dart';

import '../components/reminder_list/reminder_list_test.dart';
import '../utils/dependencies.dart';
import '../utils/test-action/test_action.dart';
import 'home_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NotificationService>()])
void main() {
  registerTestActions();

  testWidgets("tapping a reminder opens the log widget", (tester) async {
    // create an action so that the reminder list will have one item
    final a = TestAction(id: 'some-action');
    final persistence = InMemoryPersistence();
    setPersistence(persistence);
    persistence.createAction(a);

    await setReminderService();
    setNotificationService();

    // render the screen
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // tap the reminder
    await tester.tap(find.byKey(a.getKey('reminder-list-item')));
    await tester.pumpAndSettle();

    // check that the log action widget is rendered
    expect(
      find.byKey(a.getKey('log-action')),
      findsOneWidget,
    );
  });

  testWidgets("can add new action", (tester) async {
    await setReminderService();
    setNotificationService();

    final newAction = TestAction(id: 'new-action');
    Action.registerSubclass(
      serializationKey: TestAction.serializationKey,
      actionFromJson: TestAction.fromJson,
      newInstanceBuilder: (context, persistence) {
        return PokeButton.primary(
          onPressed: () {
            persistence.createAction(newAction);
          },
          key: const Key('test-action-new'),
          text: "foo",
        );
      },
    );

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // click floating action button to bring up buttons for creating new actions
    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.create));
    await tester.pumpAndSettle();

    // click the button for creating a new test action. we see this button
    // because it was registered with `Action.registerSubclass`
    await tester.tap(find.byKey(const Key('add-new-test-action')));
    await tester.pumpAndSettle();

    // click the button rendered in `newInstanceBuilder` above
    await tester.tap(find.byKey(const Key('test-action-new')));
    await tester.pumpAndSettle();

    expect(find.byKey(newAction.getKey('reminder-list-item')), findsOneWidget);
  });

  testWidgets('contains notification permission widget', (tester) async {
    setDependency<NotificationService>(MockNotificationService());
    await setUpReminderServiceMock([]);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.byType(NotificationPermissionWidget), findsOneWidget);
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
