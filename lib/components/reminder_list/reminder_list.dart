import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/persistence_event.dart';

import 'updating_reminder_list_item.dart';

/// Renders a list of reminders :)
///
/// Subscribes to a Stream<PersistenceEvent> to rerender reminders when they
/// change.
class ReminderList extends StatelessWidget {
  final List<Reminder> reminders;
  final Stream<PersistenceEvent> updatesStream;
  final Function(Reminder) onTap;
  final Function(Reminder) onSnooze;

  const ReminderList({
    super.key,
    required this.reminders,
    required this.updatesStream,
    required this.onTap,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: reminders.length,
      itemBuilder: (context, position) {
        final reminder = reminders[position];
        return UpdatingReminderListItem(
          reminder: reminder,
          onTap: onTap,
          onSnooze: onSnooze,
        );
      },
    );
  }
}
