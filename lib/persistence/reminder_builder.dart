import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/predictor/predictor.dart';

Future<List<Reminder>> buildReminders(
  Persistence persistence,
  Predictor predictor,
) async {
  final groupedByAction = await persistence.getAllEvents();
  return List.of(groupedByAction.map((awe) => buildReminder(awe, predictor)));
}

Reminder buildReminder(ActionWithEvents action, Predictor predictor) {
  return Reminder(
    actionWithEvents: action,
    dueDate: predictor.predictNext(action),
  );
}
