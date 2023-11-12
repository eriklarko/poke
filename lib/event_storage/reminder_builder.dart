import 'package:poke/event_storage/action_with_events.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/predictor/predictor.dart';

Future<List<Reminder>> buildReminders(
    EventStorage eventStorage, Predictor predictor) async {
  final groupedByAction = await eventStorage.getAll();

  List<Reminder> reminders = [];
  for (final ActionWithEvents actionWithEvents in groupedByAction) {
    final reminder = Reminder(
        actionWithEvents: actionWithEvents,
        dueDate: predictor.predictNext(actionWithEvents));

    reminders.add(reminder);
  }
  return reminders;
}
