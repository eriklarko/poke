import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/event.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

Future<Iterable<Reminder>> buildReminders(EventStorage eventStorage) async {
  final allEvents = await eventStorage.getAll();
  final grouped = grouper(allEvents);

  List<Reminder> reminders = [];
  grouped.keys.forEach((key) {
    final events = grouped[key]!;
    events.sort((a, b) => a.when.compareTo(b.when));

    final action = WaterPlantAction(
      plant: plant,
      lastEvent: events.isEmpty ? null : events[0],
    );

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

Map<Object, List<Event>> grouper(Iterable<Event> events) {
  final Map<Object, List<Event>> m = {};

  for (final event in events) {
    m.update(
      event.getKey(),
      (l) {
        l.add(event);
        return l;
      },
      ifAbsent: () => [event],
    );
  }

  return m;
}
