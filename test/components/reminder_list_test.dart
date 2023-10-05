import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/components/reminder_list.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/utils/date_formatter.dart';

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

void main() {
  testWidgets('renders all reminders', (tester) async {
    await pumpInTestApp(
      tester,
      ReminderList(reminders: [
        reminderWithLastEventAt,
        reminderWithoutLastEventAt,
      ]),
    );

    final reminders = find.byType(ReminderListItem);
    expect(reminders, findsNWidgets(2));
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
