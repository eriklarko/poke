import 'dart:async';

import 'package:flutter/material.dart';
import 'package:poke/components/reminder_list/reminder_list.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence_event.dart';

class UpdatingReminderListTestDriver extends StatelessWidget {
  final StreamController<PersistenceEvent> sc;

  final rem = Reminder(
    actionWithEvents: ActionWithEvents.single(
      WaterPlantAction(
        plant: Plant(id: "foo", name: "foo"),
      ),
      DateTime.now(),
      data: WaterEventData(addedFertilizer: false),
    ),
    dueDate: DateTime.now(),
  );

  UpdatingReminderListTestDriver({super.key}) : sc = StreamController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ReminderList(
            updatesStream: sc.stream,
            reminders: [
              rem,
            ],
            onTap: (Reminder) {},
            onSnooze: (Reminder) {},
          ),
        ),
        PokeButton.primary(
          onPressed: () {
            final u = Updating(rem.actionWithEvents.action.equalityKey);
            sc.add(u);
            Future.delayed(Duration(seconds: 2)).then((a) {
              sc.add(FinishedUpdating(u));
            });
          },
          text: 'foo',
        ),
      ],
    );
  }
}
