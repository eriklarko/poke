import 'package:flutter/material.dart' hide Overlay;
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/async_widget/state.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_tappable.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/reminder.dart';

import 'overlay.dart';

class UpdatingReminderListItem extends PokeAsyncWidget {
  UpdatingReminderListItem({
    super.key,
    required super.controller,
    required Reminder reminder,
    required Function(Reminder) onTap,
    required Function(Reminder) onSnooze,
  }) : super(
          builder: (context, state) {
            final Widget listItem = ReminderListItem(
              reminder,
              onTap: onTap,
              onSnooze: onSnooze,
            );

            return switch (state) {
              Loading() => Stack(children: [
                  listItem,
                  const Overlay(
                    child: PokeLoadingIndicator.small(color: Colors.white),
                  ),
                ]),
              Error() => Stack(children: [
                  listItem,
                  Overlay(
                    child: PokeText("NOO $state.error"),
                  ),
                ]),
              Object() => listItem,
            };
          },
        );
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
                const Positioned.fill(
                  child: Align(
                    alignment: Alignment.topRight,
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
