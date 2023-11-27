import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/predictor/predictor.dart';

Future<List<Reminder>> buildReminders(
    Persistence persistence, Predictor predictor) async {
  final groupedByAction = await persistence.getAllEvents();

  List<Reminder> reminders = [];
  for (final ActionWithEvents actionWithEvents in groupedByAction) {
    final reminder = Reminder(
        actionWithEvents: actionWithEvents,
        dueDate: predictor.predictNext(actionWithEvents));

    reminders.add(reminder);
  }
  return reminders;
}
