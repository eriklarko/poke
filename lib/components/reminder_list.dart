import 'package:flutter/material.dart';
import 'package:poke/models/reminder.dart';

class ReminderList extends StatelessWidget {
  final List<Reminder> reminders;

  const ReminderList({
    super.key,
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (context, position) => GestureDetector(
          onTap: () {
            print('Tap!');
          },
          child: ReminderListItem(reminders[position]),
        ),
      ),
    );
  }
}

class ReminderListItem extends StatelessWidget {
  final Reminder reminder;

  const ReminderListItem(this.reminder, {super.key});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: ObjectKey(reminder),

        // only allow swiping right-to-left
        direction: DismissDirection.endToStart,
        //

        background: const SnoozeAction(),
        onDismissed: (direction) {
          // TODO: Log action
          print('dismissed');
        },
        child: reminder.buildReminderListItem(context));
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
