import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/components/expandable-floating-action-button/expandable-floating-action-button.dart';
import 'package:poke/components/reminder_list/reminder_service.dart';
import 'package:poke/components/reminder_list/reminder_list.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/models/action.dart';
import 'package:poke/screens/action_details_screen/action_details_screen.dart';
import 'package:poke/utils/nav_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final Persistence persistence = GetIt.instance.get<Persistence>();

  @override
  Widget build(context) {
    return Scaffold(
      key: const ValueKey('home-screen'),
      appBar: PokeAppBar(context, title: 'hiyo'),
      body: Column(
        children: [
          const PokeHeader('hi'),
          Expanded(
            child: ReminderList(
              reminderService: ReminderService(),
              onReminderTapped: (reminder) => openLogActionDialog(
                context,
                reminder,
              ),
              swipeActions: [
                (
                  (Reminder reminder) {
                    print('snoozing $reminder');
                  },
                  Container(
                    decoration: const BoxDecoration(color: Colors.amber),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.alarm_off_sharp),
                        PokeText("snooze"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: ExpandableFab(
        distance: 110,
        children: List.of(
          Action.registeredActions().values.map((v) {
            return ActionButton(
              key: Key('add-new-${v.serializationKey}'),
              icon: const Icon(Icons.new_label),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => PokeModal(
                    child: v.newInstanceBuilder(context, persistence),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  void openLogActionDialog(context, reminder) {
    showDialog(
      context: context,
      builder: (context) => PokeModal(
        actionButton: PokeButton.icon(
          Icons.chevron_right,
          onPressed: () {
            NavService.instance.push(MaterialPageRoute(builder: (_) {
              return ActionDetailsScreen(
                actionWithEvents: reminder.actionWithEvents,
                body: reminder.buildDetailsScreen(context),
              );
            }));
          },
        ),
        child: reminder.buildLogActionWidget(context, persistence),
      ),
    );
  }
}
