import 'package:get_it/get_it.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/predictor/predictor.dart';

class ReminderService {
  final Persistence _persistence = GetIt.instance.get<Persistence>();
  final Predictor _predictor = GetIt.instance.get<Predictor>();

  Stream<ReminderUpdate>? _stream;

  Future<List<Reminder>> buildReminders() async {
    final groupedByAction = await _persistence.getAllEvents();
    return List.of(groupedByAction.map(buildReminder));
  }

  Reminder buildReminder(ActionWithEvents action) {
    return Reminder(
      actionWithEvents: action,
      dueDate: _predictor.predictNext(action),
    );
  }

  Stream<ReminderUpdate> updatesStream() {
    // ignore: prefer_conditional_assignment
    if (_stream == null) {
      _stream =
          _persistence.getNotificationStream().asyncMap(_toReminderUpdate);
    }
    return _stream!;
  }

  Future<ReminderUpdate> _toReminderUpdate(PersistenceEvent pe) async {
    if (pe is Updating) {
      return ReminderUpdate(
        actionId: pe.actionId,
        reminder: null,
        type: UpdateType.updating,
      );
    }

    final updatedAction = await _persistence.getAction(pe.actionId);
    if (updatedAction == null) {
      // The action doesn't exist in persitent storage anymore, assume it's been
      // deleted
      return ReminderUpdate(
        actionId: pe.actionId,
        reminder: null,
        type: UpdateType.removed,
      );
    }

    return ReminderUpdate(
      actionId: pe.actionId,
      reminder: buildReminder(updatedAction),
      type: UpdateType.updated,
    );
  }
}

enum UpdateType {
  updating,
  updated,
  removed,
}

class ReminderUpdate {
  final String actionId;
  final Reminder? reminder;
  final UpdateType type;

  ReminderUpdate({
    required this.actionId,
    required this.reminder,
    required this.type,
  });

  @override
  String toString() {
    return "$type - action $actionId - reminder $reminder";
  }
}
