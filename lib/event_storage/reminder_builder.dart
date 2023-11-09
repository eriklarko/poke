import 'package:poke/event_storage/action_with_events.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/reminder.dart';

Future<List<Reminder>> buildReminders(EventStorage eventStorage) async {
  final groupedByAction = await eventStorage.getAll();

  List<Reminder> reminders = [];
  for (final ActionWithEvents actionWithEvents in groupedByAction) {
    // TODO: use predictor
    final dueDate = DateTime.now();

    final reminder = Reminder(
      actionWithEvents: actionWithEvents,
      dueDate: dueDate,
    );

    reminders.add(reminder);
  }
  return reminders;
}
