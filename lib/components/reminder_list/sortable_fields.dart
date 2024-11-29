import 'package:flutter/material.dart';
import 'package:poke/models/reminder.dart';

final sortByDueDate = SortableField<Reminder>(
  key: ValueKey("sort-by-due-date"),
  icon: Icons.alarm_outlined,
  compareAsc: (a, b) {
    final aDue = a.dueDate;
    final bDue = b.dueDate;

    if (aDue == null) {
      if (bDue == null) {
        return 0;
      }

      // if `a` has no due date, but `b` does; show `b` first
      return 1;
    }

    if (bDue == null) {
      // here we know that `a` has a due date, but `b` doesn't. Show `a` first
      return -1;
    }

    // both reminders have due dates, show the oldest due date first
    return aDue.compareTo(bDue);
  },
);

final sortByLastEvent = SortableField<Reminder>(
  key: ValueKey("sort-by-last-event"),
  icon: Icons.water_drop_outlined,
  compareAsc: (a, b) {
    final aLast = a.action.getLastEvent()?.$1;
    final bLast = b.action.getLastEvent()?.$1;

    if (aLast == null) {
      if (bLast == null) {
        return 0;
      }

      // if `a` has no events, but `b` does; show `b` first
      return 1;
    }

    if (bLast == null) {
      // here we know that `a` has events, but `b` doesn't. Show `a` first
      return -1;
    }

    // both reminders have events, show the oldest event first
    return aLast.compareTo(bLast);
  },
);

class SortableField<T> {
  final Key? key;
  final IconData icon;
  final int Function(T a, T b) compareAsc;

  const SortableField({
    this.key,
    required this.icon,
    required this.compareAsc,
  });
}
