import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

import 'components/reminder_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(context) {
    return Scaffold(
      appBar: PokeAppBar(context, title: 'hiyo'),
      body: Column(children: [
        Text('hi'),
        ReminderList(
          reminders: [
            Reminder(
              action: WaterPlant(
                plant: Plant(name: 'Frank'),
                addedFertilizer: false,
                lastEventAt: DateTime.now(),
              ),
              dueDate: DateTime.now(),
            ),
          ],
          onTap: (reminder) {
            showDialog(
              context: context,
              builder: (context) => PokeModal(
                child: reminder.action.buildAddEventWidget(context),
              ),
            );
          },
          onSnooze: (reminder) => print('Snoozed $reminder'),
        ),
      ]),
    );
  }
}
