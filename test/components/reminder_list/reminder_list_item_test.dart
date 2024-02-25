import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/components/reminder_list/reminder_list_item.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/action_with_events.dart';

import '../../mock_callback.dart';
import '../../test_app.dart';
import '../../utils/test-action/test_action.dart';

final ignoreCallback = MockSingleArgCallback();
void main() {
  testWidgets('renders reminder list item based on the action', (tester) async {
    final action = TestAction(id: '1');
    final reminder = Reminder(
      actionWithEvents: ActionWithEvents(action),
      dueDate: null,
    );

    await pumpInTestApp(
      tester,
      ReminderListItem(
        reminder: reminder,
        onTap: ignoreCallback,
        onSnooze: ignoreCallback,
      ),
    );

    expect(find.byKey(action.getKey('reminder-list-item')), findsOneWidget);
  });

  group('due indicator', () {
    testWidgets('shows no icon when reminder is due in the future',
        (tester) async {
      final reminder = Reminder(
        actionWithEvents: ActionWithEvents(TestAction(id: '1')),
        // set due date to tomorrow
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );

      await pumpInTestApp(
        tester,
        ReminderListItem(
          reminder: reminder,
          onTap: ignoreCallback,
          onSnooze: ignoreCallback,
        ),
      );

      expect(find.byIcon(Icons.alarm), findsNothing);
    });

    testWidgets('shows icon when reminder is due', (tester) async {
      final reminder = Reminder(
        actionWithEvents: ActionWithEvents(TestAction(id: '1')),
        // set due date to yesterday
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      await pumpInTestApp(
        tester,
        ReminderListItem(
          reminder: reminder,
          onTap: ignoreCallback,
          onSnooze: ignoreCallback,
        ),
      );

      expect(find.byIcon(Icons.alarm), findsOneWidget);
    });
  });

  testWidgets('forwards tap to onTap callback', (tester) async {
    final reminder = Reminder(
      actionWithEvents: ActionWithEvents(TestAction(id: '1')),
      dueDate: null,
    );
    final onTap = MockSingleArgCallback<Reminder>();

    await pumpInTestApp(
      tester,
      ReminderListItem(
        reminder: reminder,
        onTap: onTap,
        onSnooze: ignoreCallback,
      ),
    );

    await tester.tap(find.byType(ReminderListItem));
    verify(onTap(reminder)).called(1);
  });

  group('swipe actions', () {
    testWidgets('renders swipe actions', (tester) async {
      fail('niy');
    });

    testWidgets('forwards tap on swipe action to caller', (tester) async {
      fail('niy');
    });
  });
}
