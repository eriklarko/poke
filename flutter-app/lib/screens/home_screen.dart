import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/components/expandable_floating_action_button/expandable_floating_action_button.dart';
import 'package:poke/components/reminder_list/reminder_list.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_permission_widget.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/screens/action_screen/action_screen.dart';
import 'package:poke/utils/nav_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final Persistence persistence = GetIt.instance.get<Persistence>();

  @override
  Widget build(context) {
    return Scaffold(
      key: const ValueKey('home-screen'),
      appBar: PokeAppBar(context, title: 'Poke'),
      body: Column(
        children: [
          const PokeHeader('hi'),
          const NotificationPermissionWidget(),
          Expanded(
            child: ReminderList(
              onReminderTapped: (reminder) {
                NavService.instance.push(MaterialPageRoute(builder: (_) {
                  return ActionScreen(
                    action: reminder.action,
                  );
                }));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ExpandableFab(
        distance: 110,
        children: List.of(
          Action.registeredActions().map((v) {
            return ActionButton(
              key: Key('add-new-${v.serializationKey}'),
              icon: const Icon(Icons.new_label),
              onPressed: () {
                PokeModal(
                  child: v.newInstanceBuilder(context, persistence),
                ).show(context);
              },
            );
          }),
        ),
      ),
    );
  }
}
