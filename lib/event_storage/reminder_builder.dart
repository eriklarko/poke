import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/reminder.dart';

Future<List<Reminder>> buildReminders(EventStorage eventStorage) async {
  final groupedByAction = await eventStorage.getAll();

  List<Reminder> reminders = [];
  for (final Action action in groupedByAction.keys) {
    // Set the last time the action was logged. This should not happen here...
    final events = groupedByAction[action]!.toList();
    events.sort((a, b) => a.compareTo(b));
    action.lastEvent = events.isEmpty ? null : events[0];

    // TODO: use predictor
    final dueDate = DateTime.now();

    final reminder = Reminder(
      action: action,
      dueDate: dueDate,
    );

    reminders.add(reminder);
  }

  // Group events based on the action
  // eg. Group all WateredPlants event into which plant was watered

  return reminders;
}
