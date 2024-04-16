import 'package:clock/clock.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence.dart';

class Reminder {
  final Action action;
  final DateTime? dueDate;

  Reminder({required this.action, required this.dueDate});

  Widget buildReminderListItem(BuildContext context) {
    return action.buildReminderListItem(context, this);
  }

  Widget buildLogActionWidget(BuildContext context, Persistence persistence) {
    return action.buildLogActionWidget(
      context,
      persistence,
    );
  }

  Widget buildDetailsScreen(BuildContext context) {
    return action.buildDetailsScreen(context);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Reminder || other.runtimeType != runtimeType) {
      return false;
    }

    return other.action == action && other.dueDate == dueDate;
  }

  @override
  int get hashCode {
    return action.hashCode + dueDate.hashCode;
  }

  @override
  String toString() {
    return "$action due $dueDate";
  }

  bool isDue() {
    if (dueDate == null) {
      return false;
    }

    return clock.now().isAfter(dueDate!);
  }
}
