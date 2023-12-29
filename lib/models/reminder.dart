import 'package:clock/clock.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';

class Reminder {
  final ActionWithEvents actionWithEvents;
  final DateTime? dueDate;

  Reminder({required this.actionWithEvents, required this.dueDate});

  Widget buildReminderListItem(BuildContext context) {
    return actionWithEvents.action.buildReminderListItem(
      context,
      actionWithEvents.getLastEvent(),
    );
  }

  Widget buildLogActionWidget(BuildContext context, Persistence persistence) {
    return actionWithEvents.action.buildLogActionWidget(
      context,
      actionWithEvents.getLastEvent(),
      persistence,
    );
  }

  Widget buildDetailsScreen(BuildContext context) {
    return actionWithEvents.action.buildDetailsScreen(
      context,
      actionWithEvents.events,
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

  bool isDue() {
    if (dueDate == null) {
      return false;
    }

    return clock.now().isAfter(dueDate!);
  }
}
