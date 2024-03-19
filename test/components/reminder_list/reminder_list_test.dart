import 'dart:async';

import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/components/reminder_list/reminder_service.dart';
import 'package:poke/components/reminder_list/reminder_list.dart';
import 'package:poke/components/reminder_list/reminder_list_item.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/predictor/predictor.dart';

import '../../mock_callback.dart';
import '../../test_app.dart';
import '../../utils/persistence.dart';
import '../../utils/test-action/test_action.dart';
import 'reminder_list_test.mocks.dart';

final MockSingleArgCallback ignoreCallback = MockSingleArgCallback();

MockReminderService reminderServiceMock(List<Reminder> reminders) {
  final mrf = MockReminderService();

  for (final reminder in reminders) {
    when(mrf.buildReminder(reminder.actionWithEvents)).thenReturn(reminder);
  }

  when(mrf.buildReminders()).thenAnswer(
    (realInvocation) => Future.value(reminders),
  );

  return mrf;
}

StreamController<ReminderUpdate> addStream(MockReminderService mrf) {
  final sc = StreamController<ReminderUpdate>();
  when(mrf.updatesStream()).thenAnswer((_) => sc.stream);
  return sc;
}

@GenerateNiceMocks([MockSpec<ReminderService>(), MockSpec<Predictor>()])
void main() {
  final reminder = Reminder(
    actionWithEvents: ActionWithEvents(TestAction(id: 'test-action-1')),
    // set due date to tomorrow
    dueDate: DateTime.now().add(const Duration(days: 1)),
  );
  final expiredReminder = Reminder(
    actionWithEvents: ActionWithEvents(TestAction(id: 'test-action-2')),
    // set due date to yesterday
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
  );

  testWidgets('renders all reminders', (tester) async {
    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: reminderServiceMock([reminder, expiredReminder]),
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    final reminders = find.byType(ReminderListItem);
    expect(reminders, findsNWidgets(2));
  });

  testWidgets('the onTap callback is invoked when tapping a reminder',
      (tester) async {
    final onTapCallback = MockSingleArgCallback<Reminder>();

    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: reminderServiceMock([reminder]),
        onReminderTapped: onTapCallback,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ReminderListItem));
    verify(onTapCallback(reminder)).called(1);
  });

  testWidgets('expired reminders are marked', (tester) async {
    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: reminderServiceMock([reminder, expiredReminder]),
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    final expiredReminders = find.byIcon(Icons.alarm);
    expect(expiredReminders, findsOneWidget);
  });

  testWidgets('allows retrying when building reminders fail', (tester) async {
    final reminderService = MockReminderService();
    when(reminderService.buildReminders()).thenThrow("test error");

    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: reminderService,
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pump();

    // check that the error is shown
    expect(
      find.text("test error"),
      findsOneWidget,
    );

    // tap the retry button
    await tester.tap(find.byKey(const Key('retry')));
    verify(reminderService.buildReminders()).called(2);
  });

  testWidgets("shows loading indicator while loading reminders",
      (tester) async {
    // set up reminder service taking 2s to load reminders
    final reminderService = MockReminderService();
    when(reminderService.buildReminders()).thenAnswer(
      (_) => Future.delayed(const Duration(
        seconds: 2,
      )).then((value) => []),
    );

    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: reminderService,
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pump();

    expect(
      find.byType(PokeLoadingIndicator),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('renders new action when it is added', (tester) async {
    final mockReminderService = reminderServiceMock([reminder]);
    final sc = addStream(mockReminderService);

    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: mockReminderService,
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    final newAction = TestAction(id: 'new-action');
    sc.add(ReminderUpdate(
      actionId: newAction.equalityKey,
      reminder: Reminder(
        actionWithEvents: ActionWithEvents(newAction),
        dueDate: DateTime.now(),
      ),

      // there's no `added` update type because the reminder service can't know
      // when a new reminder is added.
      //
      // the reminder service doesn't keep a list of reminders it has seen, so
      // when it gets notified about a reminder it cannot check if it has seen
      // the action before or not
      type: UpdateType.updated,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(newAction.getKey('reminder-list-item')), findsOneWidget);
  });

  testWidgets('removes reminder from list when action is removed',
      (tester) async {
    final mockReminderService = reminderServiceMock([reminder]);
    final sc = addStream(mockReminderService);

    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: mockReminderService,
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    sc.add(ReminderUpdate(
      // this id must match at least one reminder in the reminder service
      actionId: reminder.actionWithEvents.action.equalityKey,
      reminder: null,
      type: UpdateType.removed,
    ));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        Key(reminder.actionWithEvents.action.equalityKey),
      ),
      findsNothing,
    );
  });

  testWidgets('shows loading indicator while list item data is updated',
      (tester) async {
    final mockReminderService = reminderServiceMock([reminder]);
    final sc = addStream(mockReminderService);

    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: mockReminderService,
        onReminderTapped: ignoreCallback,
      ),
    );
    await tester.pumpAndSettle();

    // verify that no loading indicator is shown before sending the `updating`
    // event
    expect(find.byType(PokeLoadingIndicator), findsNothing);

    // send an `updating` event on the stream, indicating which reminder is
    // being updated
    sc.add(
      ReminderUpdate(
        actionId: reminder.actionWithEvents.action.equalityKey,
        reminder: null,
        type: UpdateType.updating,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PokeLoadingIndicator), findsOneWidget);
  });

  testWidgets('rerenders when visible persistence data is changed',
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
    await pumpInTestApp(
      tester,
      ReminderList(
        reminderService: ReminderService(),
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
}
