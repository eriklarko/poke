import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_tappable.dart';
import 'package:poke/models/reminder.dart';

class ReminderList extends StatelessWidget {
  final List<Reminder> reminders;
  final Function(Reminder) onTap;
  final Function(Reminder) onSnooze;

  const ReminderList({
    super.key,
    required this.reminders,
    required this.onTap,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (context, position) => ReminderListItem(
          reminders[position],
          onTap: onTap,
          onSnooze: onSnooze,
        ),
      ),
    );
  }
}

class ReminderListItem extends StatelessWidget {
  final Reminder reminder;
  final Function(Reminder) onTap;
  final Function(Reminder) onSnooze;

  const ReminderListItem(
    this.reminder, {
    super.key,
    required this.onTap,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return PokeTappable(
      onTap: () {
        print('Tap!');
        onTap(reminder);
      },
      child: Dismissible(
          key: ObjectKey(reminder),

          // only allow swiping right-to-left
          direction: DismissDirection.endToStart,
          //

          background: const SnoozeAction(),
          onDismissed: (direction) {
            // TODO: Log action
            print('dismissed!');
            onSnooze(reminder);
          },
          child: reminder.buildReminderListItem(context)),
    );
  }
}

class SnoozeAction extends StatelessWidget {
  const SnoozeAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber,
      child: const Padding(
        padding: EdgeInsets.only(right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Snooze'),
            Icon(Icons.snooze),
          ],
        ),
      ),
    );
  }
}
