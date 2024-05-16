import 'dart:async';
import 'dart:collection';

import 'package:get_it/get_it.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/predictor/predictor.dart';

class ReminderService {
  final Persistence _persistence = GetIt.instance.get<Persistence>();
  final Predictor _predictor = GetIt.instance.get<Predictor>();
  late List<Reminder> _reminders;

  StreamController<ReminderUpdate>? _publicStream;
  StreamSubscription? _reminderUpdateStreamSubscription;

  Future<void> init() async {
    final actions = await _persistence.getAllActions();
    _reminders = List.of(actions.map(buildReminder));

    if (!_persistenceStreamRegistered()) {
      _reminderUpdateStreamSubscription = _persistence
          .getNotificationStream()
          .asyncMap(_toReminderUpdate)
          .listen(_onUpdateReceived);
    }
  }

  bool _persistenceStreamRegistered() {
    // impl from https://stackoverflow.com/a/69301540/615496
    final sc = StreamController();
    sc.addStream(_persistence.getNotificationStream());
    return sc.hasListener;
  }

  Future<void> dispose() async {
    await _reminderUpdateStreamSubscription?.cancel();
  }

  void _onUpdateReceived(ReminderUpdate update) async {
    if (update.type == UpdateType.removed) {
      // reminder removed
      _removeReminder(update.actionId);
    } else if (update.reminder != null) {
      // got new reminder info, best stay up-to-date
      final reminder = update.reminder!;
      if (knowsAction(reminder.action.equalityKey)) {
        _updateReminder(reminder);
      } else {
        _addReminder(reminder);
      }
    }

    // forward update to any listeners
    _publicStream?.add(update);
  }

  bool knowsAction(String actionId) {
    return _reminders.any(
      (reminder) => reminder.action.equalityKey == actionId,
    );
  }

  void _addReminder(Reminder reminder) {
    _reminders.add(reminder);
  }

  void _removeReminder(String actionId) {
    _reminders.removeWhere(
      (reminder) => reminder.action.equalityKey == actionId,
    );
  }

  void _updateReminder(Reminder reminder) {
    // find the index in `_reminders` where the action is
    final i = _reminders.indexWhere((reminder) {
      return reminder.action.equalityKey == reminder.action.equalityKey;
    });
    // and replace the reminder
    _reminders[i] = reminder;
  }

  UnmodifiableListView<Reminder> getReminders() {
    return UnmodifiableListView(_reminders);
  }

  Reminder buildReminder(Action action) {
    return Reminder(
      action: action,
      dueDate: _predictor.predictNext(action),
    );
  }

  Stream<ReminderUpdate> updatesStream() {
    _publicStream ??= StreamController.broadcast();
    return _publicStream!.stream;
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
      type: knowsAction(pe.actionId) ? UpdateType.updated : UpdateType.added,
    );
  }
}

enum UpdateType {
  updating,
  added,
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
