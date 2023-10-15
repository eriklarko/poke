import 'package:flutter/material.dart' hide Action;
import 'package:poke/models/action.dart';
import 'package:poke/utils/date_formatter.dart';

class Reminder {
  final Action action;
  final DateTime dueDate;

  Reminder({required this.action, required this.dueDate});

  Widget buildReminderListItem(BuildContext context) {
    return action.buildReminderListItem(context);
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
}
