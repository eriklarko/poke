import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/event.dart';
import 'package:poke/models/reminder.dart';

Future<Iterable<Reminder>> buildReminders(EventStorage eventStorage) async {
  final allEvents = await eventStorage.getAll();
  final groupedByAction = groupByAction(allEvents);

  List<Reminder> reminders = [];
  groupedByAction.keys.forEach((action) {
    // Set the last time the action was logged. This should not happen here...
    final events = groupedByAction[action]!;
    events.sort((a, b) => a.compareTo(b));
    action.lastEvent = events.isEmpty ? null : events[0];

    // TODO: use predictor
    final dueDate = DateTime.now();

    final reminder = Reminder(
      action: action,
      dueDate: dueDate,
    );

    reminders.add(reminder);
  });

  // Group events based on the action
  // eg. Group all WateredPlants event into which plant was watered

  return reminders;
}

Map<Action, List<DateTime>> groupByAction(Iterable<Event> events) {
  final Map<Action, List<DateTime>> m = {};

  for (final event in events) {
    m.update(
      event.action,
      (l) {
        l.add(event.when);
        return l;
      },
      ifAbsent: () => [event.when],
    );
  }

  return m;
}
