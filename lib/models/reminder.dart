import 'package:flutter/material.dart' hide Action;
import 'package:poke/event_storage/action_with_events.dart';
import 'package:poke/event_storage/event_storage.dart';

class Reminder {
  final ActionWithEvents actionWithEvents;
  final DateTime dueDate;

  Reminder({required this.actionWithEvents, required this.dueDate});

  Widget buildReminderListItem(BuildContext context) {
    return actionWithEvents.action.buildReminderListItem(
      context,
      actionWithEvents.getLastEvent(),
    );
  }

  Widget buildLogActionWidget(BuildContext context, EventStorage eventStorage) {
    return actionWithEvents.action.buildLogActionWidget(
      context,
      actionWithEvents.getLastEvent(),
      eventStorage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! Reminder || other.runtimeType != runtimeType) {
      return false;
    }

    return other.actionWithEvents == actionWithEvents &&
        other.dueDate == dueDate;
  }

  @override
  int get hashCode {
    return actionWithEvents.hashCode + dueDate.hashCode;
  }

  @override
  String toString() {
    return "${actionWithEvents.action} due $dueDate";
  }
}
