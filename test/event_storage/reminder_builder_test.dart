import 'package:flutter_test/flutter_test.dart';
import 'package:poke/event_storage/action_with_events.dart';
import 'package:poke/event_storage/in_memory_storage.dart';
import 'package:poke/event_storage/reminder_builder.dart';
import 'package:poke/models/reminder.dart';

import '../utils/test-action/test_action.dart';

void main() {
  test('reminds about existing events', () async {
    final eventStorage = InMemoryStorage();

    final action = TestAction(id: '1');
    final ts = DateTime.now();
    await eventStorage.logAction(action, ts);

    expect(
      await buildReminders(eventStorage),
      equals([
        Reminder(
          actionWithEvents: ActionWithEvents.single(action, ts),
          dueDate: DateTime.now(),
        ),
      ]),
    );
  });
}
