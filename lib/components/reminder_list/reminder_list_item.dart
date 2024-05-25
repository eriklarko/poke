import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_swipeable.dart';
import 'package:poke/design_system/poke_tappable.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/reminder.dart';

class ReminderListItem extends StatelessWidget {
  final Reminder reminder;
  final Function(Reminder) onTap;
  final List<SwipeAction<Reminder>>? swipeActions;

  const ReminderListItem({
    required this.reminder,
    super.key,
    required this.onTap,
    this.swipeActions,
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
        child: PokeSwipeable<Reminder>(
          key: ObjectKey(reminder),
          value: reminder,
          swipeActions: swipeActions ?? [],
          child: Stack(
            children: [
              if (reminder.isDue())
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: PokeConstants.space()),
                      child: const Icon(Icons.alarm, color: Colors.redAccent),
                    ),
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
