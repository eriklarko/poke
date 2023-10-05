import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/components/reminder_list.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/reminder.dart';

import '../drag_directions.dart';
import '../mock_callback.dart';
import '../test_app.dart';

final reminderWithLastEventAt = Reminder(
  action: TestAction('test-action-with-lastEventAt'),
  dueDate: DateTime.now(),
  lastEventAt: DateTime.parse('1963-11-23 01:02:03'),
);
final reminderWithoutLastEventAt = Reminder(
  action: TestAction('test-action-without-lastEventAt'),
  dueDate: DateTime.now(),
);

final ignoreCallback = MockCallback<Reminder>();

void main() {
  testWidgets('renders all reminders', (tester) async {
    await pumpInTestApp(
      tester,
      ReminderList(
        reminders: [
          reminderWithLastEventAt,
          reminderWithoutLastEventAt,
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
    final onTapCallback = MockCallback<Reminder>();

    await pumpInTestApp(
      tester,
      ReminderList(
        reminders: [
          reminderWithLastEventAt,
        ],
        onTap: onTapCallback,
        onSnooze: ignoreCallback,
      ),
    );

    await tester.tap(find.byType(ReminderListItem));

    verify(onTapCallback(reminderWithLastEventAt)).called(1);
  });

  testWidgets('endToStart swipe snoozes reminder', (tester) async {
    final onSnoozeCallback = MockCallback<Reminder>();

    await pumpInTestApp(
      tester,
      ReminderList(
        reminders: [
          reminderWithLastEventAt,
        ],
        onTap: ignoreCallback,
        onSnooze: onSnoozeCallback,
      ),
    );

    await tester.drag(find.byType(ReminderListItem), endToStart);
    await tester.pumpAndSettle();

    verify(onSnoozeCallback(reminderWithLastEventAt)).called(1);
  });
}

class TestAction implements Action {
  final String id;

  TestAction(this.id);

  @override
  Widget buildReminderListItem(BuildContext context, {DateTime? lastEventAt}) {
    return Column(
      key: Key(id),
      children: [
        Text(id),
      ],
    );
  }
}
