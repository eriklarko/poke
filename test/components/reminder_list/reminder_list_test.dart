import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/reminder_service/reminder_service.dart';
import 'package:poke/components/reminder_list/reminder_list.dart';
import 'package:poke/components/reminder_list/reminder_list_item.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/predictor/predictor.dart';

import '../../mock_callback.dart';
import '../../test_app.dart';
import '../../utils/dependencies.dart';
import '../../utils/test-action/test_action.dart';
import 'reminder_list_test.mocks.dart';

final MockSingleArgCallback ignoreCallback = MockSingleArgCallback();

Future<ReminderService> setUpReminderServiceMock(
  List<Reminder> reminders, [
  Persistence? persistence,
]) async {
  final predictor = MockPredictor();
  for (final reminder in reminders) {
    when(predictor.predictNext(reminder.action)).thenReturn(reminder.dueDate);
  }
  setDependency<Predictor>(predictor);

  persistence ??= InMemoryPersistence();
  if (persistence is InMemoryPersistence) {
    for (final r in reminders) {
      await persistence.createAction(r.action);
    }
    setDependency<Persistence>(persistence);
  } else {
    throw "Unsupported persistence ${persistence.runtimeType}";
  }

  final rs = ReminderService();
  await rs.init();
  await setReminderService(false, rs);
  return rs;
}

@GenerateNiceMocks([MockSpec<ReminderService>(), MockSpec<Predictor>()])
void main() {
  registerTestActions();

  final reminder = Reminder(
    action: TestAction(id: 'test-action-1'),
    // set due date to tomorrow
    dueDate: DateTime.now().add(const Duration(days: 1)),
  );
  final expiredReminder = Reminder(
    action: TestAction(id: 'test-action-2'),
    // set due date to yesterday
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  );

  testWidgets('renders all reminders', (tester) async {
    await setUpReminderServiceMock([reminder, expiredReminder]);

    await pumpInTestApp(
      tester,
      ReminderList(
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    final reminders = find.byType(ReminderListItem);
    expect(reminders, findsNWidgets(2));
  });

  testWidgets('the onTap callback is invoked when tapping a reminder',
      (tester) async {
    await setUpReminderServiceMock([reminder]);

    final onTapCallback = MockSingleArgCallback<Reminder>();
    await pumpInTestApp(
      tester,
      ReminderList(
        onReminderTapped: onTapCallback,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ReminderListItem));
    verify(onTapCallback(reminder)).called(1);
  });

  testWidgets('expired reminders are marked', (tester) async {
    await setUpReminderServiceMock([reminder, expiredReminder]);
    await pumpInTestApp(
      tester,
      ReminderList(
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    final expiredReminders = find.byIcon(Icons.alarm);
    expect(expiredReminders, findsOneWidget);
  });

  testWidgets('renders new action when it is added', (tester) async {
    final persistence = InMemoryPersistence();
    await setUpReminderServiceMock([reminder], persistence);

    await pumpInTestApp(
      tester,
      ReminderList(
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    final newAction = TestAction(id: 'new-action');
    await persistence.createAction(newAction);
    await tester.pumpAndSettle();

    expect(find.byKey(newAction.getKey('reminder-list-item')), findsOneWidget);
  });

  testWidgets('removes reminder from list when action is removed',
      (tester) async {
    await tester.runAsync(() async {
      final persistence = InMemoryPersistence();
      await setUpReminderServiceMock([reminder], persistence);
      final action = reminder.action as TestAction;

      await pumpInTestApp(
        tester,
        ReminderList(
          onReminderTapped: ignoreCallback,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(action.getKey('reminder-list-item')),
        findsOneWidget,
      );

      print("DELETING EVENT");
      await persistence.deleteAction(reminder.action.equalityKey);
      await pumpEventQueue();

      expect(
        find.byKey(action.getKey('reminder-list-item')),
        findsNothing,
      );
    });
  });

  testWidgets('shows loading indicator while list item data is updated',
      (tester) async {
    final persistence = InMemoryPersistence();
    await setUpReminderServiceMock([reminder], persistence);

    await pumpInTestApp(
      tester,
      ReminderList(
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    // verify that no loading indicator is shown before sending the `updating`
    // event
    expect(find.byType(PokeLoadingIndicator), findsNothing);

    // send an `updating` event on the persistence stream, indicating which
    // action is being updated
    persistence.notificationStreamController.add(
      PersistenceEvent.updating(actionId: reminder.action.equalityKey),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PokeLoadingIndicator), findsOneWidget);
  });

  testWidgets('rerenders when visible persistence data is changed',
      (tester) async {
    // create the action being shown to the user
    final action = TestActionWithData(id: 'some-action');
    final persistence = InMemoryPersistence();
    persistence.logAction(
      action,
      DateTime.now(),
      eventData: Data("first-data"),
    );

    // set up reminder service dependency
    await setUpReminderServiceMock([], persistence);

    // render reminders for the action
    await pumpInTestApp(
      tester,
      ReminderList(
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    // check that the first data is shown
    expect(find.text("first-data"), findsOneWidget);

    // add a new event to the data, rendering its data instead
    persistence.logAction(
      action,
      DateTime.now(),
      eventData: Data("second-data"),
    );
    await tester.pumpAndSettle();

    // check that this second data is shown
    expect(find.text("second-data"), findsOneWidget);
  });

  testWidgets("renders most due reminders first", (tester) async {
    // create some reminders, each with different due dates
    final mostDueReminder = Reminder(
      action: TestAction(id: 'test-action-1'),
      // ten days ago
      dueDate: DateTime.now().subtract(const Duration(days: 10)),
    );
    final secondMostDueReminder = Reminder(
      action: TestAction(id: 'test-action-2'),
      // five days ago
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
    );
    final leastDueReminder = Reminder(
      action: TestAction(id: 'test-action-3'),
      // in ten days
      dueDate: DateTime.now().add(const Duration(days: 10)),
    );
    final reminderWithNoDueDate = Reminder(
      action: TestAction(id: 'test-action-4'),
      dueDate: null,
    );

    await setUpReminderServiceMock([
      // to increase confidence that the test is working as expected, don't
      // add the reminders in the expected order
      secondMostDueReminder,
      reminderWithNoDueDate,
      leastDueReminder,
      mostDueReminder,
    ]);

    // render them
    await pumpInTestApp(
      tester,
      ReminderList(
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    // check that they're shown in increasing due date order
    final renderedRemindersInOrder = tester
        .widgetList<ReminderListItem>(
          find.byType(ReminderListItem),
        )
        .toList()
        .map((listItem) => listItem.reminder);

    expect(
      renderedRemindersInOrder,
      equals(
        [
          mostDueReminder,
          secondMostDueReminder,
          leastDueReminder,
          reminderWithNoDueDate,
        ],
      ),
    );
  });
}
