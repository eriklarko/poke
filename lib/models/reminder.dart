import 'package:flutter/material.dart' hide Action;
import 'package:poke/models/action.dart';

class Reminder {
  final Action action;
  final DateTime dueDate;
  final DateTime? lastEventAt;

  Reminder({required this.action, required this.dueDate, this.lastEventAt});

  Widget buildReminderListItem(BuildContext context) {
    return action.buildReminderListItem(
      context,
      lastEventAt: lastEventAt,
    );
  }
}
