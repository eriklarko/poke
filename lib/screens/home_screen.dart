import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/components/expandable-floating-action-button/expandable-floating-action-button.dart';
import 'package:poke/components/reminder_list/reminder_list.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/reminder_builder.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/predictor/predictor.dart';
import 'package:poke/screens/action_details_screen/action_details_screen.dart';
import 'package:poke/utils/nav_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final Persistence persistence = GetIt.instance.get<Persistence>();
  static final Predictor predictor = GetIt.instance.get<Predictor>();

  final Future<List<Reminder>> _remFut = buildReminders(
    persistence,
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
                updatesStream: Stream.empty(),
                reminders: reminders,
                onTap: (reminder) {
                  showDialog(
                    context: context,
                    builder: (context) => PokeModal(
                      actionButton: PokeButton.icon(
                        const Icon(Icons.chevron_right),
                        onPressed: () {
                          NavService.instance
                              .push(MaterialPageRoute(builder: (_) {
                            return ActionDetailsScreen(
                              actionWithEvents: reminder.actionWithEvents,
                              body: reminder.buildDetailsScreen(context),
                            );
                          }));
                        },
                      ),
                      child:
                          reminder.buildLogActionWidget(context, persistence),
                    ),
                  );
                },
                onSnooze: (reminder) => PokeLogger.instance()
                    .info('Snoozed reminder', data: {'reminder': reminder}),
              );
            })
      ]),
      floatingActionButton: ExpandableFab(
        distance: 110,
        children: List.of(
          Action.registeredActions().values.map((v) {
            return ActionButton(
              icon: const Icon(Icons.new_label),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => PokeModal(
                    child: v.newInstanceBuilder(context, persistence),
                  ),
                );
                print('foof');
              },
            );
          }),
        ),
      ),
    );
  }
}
