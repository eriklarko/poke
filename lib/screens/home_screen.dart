import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/components/reminder_list.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/event_storage/reminder_builder.dart';
import 'package:poke/models/reminder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final EventStorage eventStorage = GetIt.instance.get<EventStorage>();
  final Future<List<Reminder>> _remFut = buildReminders(eventStorage);

  @override
  Widget build(context) {
    return Scaffold(
      appBar: PokeAppBar(context, title: 'hiyo'),
      body: Column(children: [
        const PokeHeader('hi'),
        PokeFutureBuilder<List<Reminder>>(
            future: _remFut,
            child: (reminders) {
              return ReminderList(
                reminders: reminders,
                onTap: (reminder) {
                  showDialog(
                    context: context,
                    builder: (context) => PokeModal(
                      child: reminder.action
                          .buildLogActionWidget(context, eventStorage),
                    ),
                  );
                },
                onSnooze: (reminder) => print('Snoozed $reminder'),
              );
            })
      ]),
    );
  }
}
