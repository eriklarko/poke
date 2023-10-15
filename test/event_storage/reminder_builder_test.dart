import 'package:flutter_test/flutter_test.dart';
import 'package:poke/event_storage/in_memory_storage.dart';
import 'package:poke/event_storage/reminder_builder.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/test-action/test_action.dart';

void main() {
  test('reminds about existing events', () async {
    final eventStorage = InMemoryStorage();

    final action = TestAction(id: '1');
    await eventStorage.logAction(action, DateTime.now());

    expect(
      await buildReminders(eventStorage),
      equals([
        Reminder(
          action: action,
          dueDate: DateTime.now(),
        ),
      ]),
    );
  });
}
