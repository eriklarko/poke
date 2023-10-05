import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_app_bar.dart';
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
              ),
              dueDate: DateTime.now(),
              lastEventAt: DateTime.now(),
            ),
          ],
          onTap: (reminder) => print('Tapped $reminder'),
          onSnooze: (reminder) => print('Snoozed $reminder'),
        ),
      ]),
    );
  }
}
