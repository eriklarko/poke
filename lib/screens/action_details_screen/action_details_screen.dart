import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/screens/action_details_screen/event_history.dart';
import 'package:poke/utils/future_helpers.dart';

// TODO: Add delete functionality
class ActionDetailsScreen extends StatelessWidget {
  final notificationService = GetIt.instance.get<NotificationService>();

  final Action action;
  final Widget body;

  ActionDetailsScreen({
    super.key,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PokeAppBar(context),
        body: Column(
          children: [
            body,
            PokeFutureBuilder<ScheduledNotification?>(
              future: asFuture(
                notificationService.getScheduledNotificationForAction(action),
              ),
              child: (notification) {
                if (notification == null) {
                  return PokeText("No notification scheduled");
                } else {
                  return PokeText(
                    "Notification scheduled for ${notification.$2}",
                  );
                }
              },
            ),
            Expanded(
              child: EventHistory(action: action),
            ),
          ],
        ));
  }
}
