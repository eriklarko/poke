import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/components/reminder_list/reminder_list_item.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/action_with_events.dart';

import '../../drag_directions.dart';
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
      ),
    );

    await tester.tap(find.byType(ReminderListItem));
    verify(onTap(reminder)).called(1);
  });

  testWidgets('renders swipe actions', (tester) async {
    final swipeActionCallback = MockSingleArgCallback();
    final reminder = Reminder(
      actionWithEvents: ActionWithEvents(TestAction(id: '1')),
      dueDate: null,
    );

    // render list item
    await pumpInTestApp(
      tester,
      ReminderListItem(
        reminder: reminder,
        onTap: ignoreCallback,
        swipeActions: [
          (
            swipeActionCallback,
            const PokeText("swipe-action"),
          )
        ],
      ),
    );

    // swipe it a bit to reveal the swipe action
    await tester.drag(find.byType(ReminderListItem), endToStart);
    await tester.pumpAndSettle();

    // tap the swipe action and verify that its callback was invoked
    await tester.tap(find.text('swipe-action'));
    verify(swipeActionCallback(reminder)).called(1);
  });
}
