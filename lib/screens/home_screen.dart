import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/components/expandable-floating-action-button/expandable-floating-action-button.dart';
import 'package:poke/components/reminder_list.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/event_storage/reminder_builder.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/predictor/predictor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final EventStorage eventStorage = GetIt.instance.get<EventStorage>();
  static final Predictor predictor = GetIt.instance.get<Predictor>();

  final Future<List<Reminder>> _remFut = buildReminders(
    eventStorage,
    predictor,
  );

  @override
  Widget build(context) {
    return Scaffold(
      key: const ValueKey('home-screen'),
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
                      child:
                          reminder.buildLogActionWidget(context, eventStorage),
                    ),
                  );
                },
                onSnooze: (reminder) => PokeLogger.instance()
                    .info('Snoozed reminder', data: {'reminder': reminder}),
              );
            })
      ]),
      floatingActionButton: const ExpandableFab(
        distance: 110,
        children: [
          ActionButton(
            icon: Icon(Icons.new_label),
          ),
        ],
      ),
    );
  }
}
