import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/components/reminder_list/reminder_list.dart';
import 'package:poke/components/reminder_list/reminder_list_item.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/persistence_event.dart';

import '../../drag_directions.dart';
import '../../mock_callback.dart';
import '../../test_app.dart';
import '../../utils/test-action/test_action.dart';

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

final ignoreCallback = MockSingleArgCallback<Reminder>();

void main() {
  final testApp = pumpInTestAppFactory(
    (widgetUnderTest) => Expanded(child: widgetUnderTest),
  );

  testWidgets('renders all reminders', (tester) async {
    await testApp(
      tester,
      ReminderList(
        reminders: [
          reminder,
          expiredReminder,
        ],
        updatesStream: const Stream.empty(),
        onTap: ignoreCallback,
        onSnooze: ignoreCallback,
      ),
    );

    final reminders = find.byType(ReminderListItem);
    expect(reminders, findsNWidgets(2));
  });

  testWidgets('onTap callback is invoked when tapping the reminder',
      (tester) async {
    final onTapCallback = MockSingleArgCallback<Reminder>();

    await testApp(
      tester,
      ReminderList(
        reminders: [
          reminder,
        ],
        updatesStream: const Stream.empty(),
        onTap: onTapCallback,
        onSnooze: ignoreCallback,
      ),
    );

    await tester.tap(find.byType(ReminderListItem));

    verify(onTapCallback(reminder)).called(1);
  });

  testWidgets('expired reminders are marked', (tester) async {
    await testApp(
      tester,
      ReminderList(
        reminders: [
          reminder,
          expiredReminder,
        ],
        updatesStream: const Stream.empty(),
        onTap: ignoreCallback,
        onSnooze: ignoreCallback,
      ),
    );

    final expiredReminders = find.byIcon(Icons.alarm);
    expect(expiredReminders, findsOneWidget);
  });

  testWidgets('endToStart swipe snoozes reminder', (tester) async {
    final onSnoozeCallback = MockSingleArgCallback<Reminder>();

    await testApp(
      tester,
      ReminderList(
        reminders: [
          reminder,
        ],
        updatesStream: const Stream.empty(),
        onTap: ignoreCallback,
        onSnooze: onSnoozeCallback,
      ),
    );

    await tester.drag(find.byType(ReminderListItem), endToStart);
    await tester.pumpAndSettle();

    verify(onSnoozeCallback(reminder)).called(1);
  });

  testWidgets('shows loading indicator while list item data is updated',
      (tester) async {
    final sc = StreamController<PersistenceEvent>();

    await testApp(
      tester,
      ReminderList(
        reminders: [
          reminder,
        ],
        updatesStream: sc.stream,
        onTap: ignoreCallback,
        onSnooze: ignoreCallback,
      ),
    );

    // send an `updating` event on the stream, indicating which reminder is
    // being updated
    sc.add(
      PersistenceEvent.updating(
        actionId: reminder.actionWithEvents.action.equalityKey,
      ),
    );
    await tester.pump();
    expect(find.byType(PokeLoadingIndicator), findsOneWidget);
  });
}
