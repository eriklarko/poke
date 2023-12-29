import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_tappable.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
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
          PokeLogger.instance().debug(
            'Tapped reminder',
            data: {'reminder': reminder},
          );
          onTap(reminder);
        },
        child: Dismissible(
          key: ObjectKey(reminder),

          // only allow swiping right-to-left
          direction: DismissDirection.endToStart,
          //

          background: const SnoozeAction(),
          onDismissed: (direction) {
            PokeLogger.instance().info(
              'dismissed reminder',
              data: {'reminder': reminder},
            );
            onSnooze(reminder);
          },
          child: Stack(
            children: [
              if (reminder.isDue())
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.alarm, color: Colors.redAccent),
                  ),
                ),
              Row(
                children: [
                  Expanded(child: reminder.buildReminderListItem(context)),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ));
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
            PokeText('Snooze'),
            Icon(Icons.snooze),
          ],
        ),
      ),
    );
  }
}
