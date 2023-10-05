import 'package:flutter/material.dart' hide Action;
import 'package:poke/models/action.dart';

class Reminder {
  final Action action;
  final DateTime dueDate;

  Reminder({required this.action, required this.dueDate});

  Widget buildReminderListItem(BuildContext context) {
    return action.buildReminderListItem(context);
  }
}
