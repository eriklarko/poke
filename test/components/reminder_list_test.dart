import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/components/reminder_list.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/models/reminder.dart';

import '../drag_directions.dart';
import '../mock_callback.dart';
import '../test_app.dart';
import '../utils/test-action/test_action.dart';

final reminder1 = Reminder(
  actionWithEvents: ActionWithEvents(TestAction(id: 'test-action-1')),
  dueDate: DateTime.now(),
);
final reminder2 = Reminder(
  actionWithEvents: ActionWithEvents(TestAction(id: 'test-action-2')),
  dueDate: DateTime.now(),
);

final ignoreCallback = MockSingleArgCallback<Reminder>();

void main() {
  testWidgets('renders all reminders', (tester) async {
    await pumpInTestApp(
      tester,
      ReminderList(
        reminders: [
          reminder1,
          reminder2,
        ],
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

    await pumpInTestApp(
      tester,
      ReminderList(
        reminders: [
          reminder1,
        ],
        onTap: onTapCallback,
        onSnooze: ignoreCallback,
      ),
    );

    await tester.tap(find.byType(ReminderListItem));

    verify(onTapCallback(reminder1)).called(1);
  });

  testWidgets('endToStart swipe snoozes reminder', (tester) async {
    final onSnoozeCallback = MockSingleArgCallback<Reminder>();

    await pumpInTestApp(
      tester,
      ReminderList(
        reminders: [
          reminder1,
        ],
        onTap: ignoreCallback,
        onSnooze: onSnoozeCallback,
      ),
    );

    await tester.drag(find.byType(ReminderListItem), endToStart);
    await tester.pumpAndSettle();

    verify(onSnoozeCallback(reminder1)).called(1);
  });

  testWidgets('expired reminders are marked', (tester) async {
    fail('');
  });
}
