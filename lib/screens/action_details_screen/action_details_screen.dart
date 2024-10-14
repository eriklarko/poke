import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/screens/action_details_screen/event_history.dart';
import 'package:poke/screens/home_screen.dart';
import 'package:poke/utils/future_helpers.dart';
import 'package:poke/utils/nav_service.dart';

class ActionDetailsScreen extends StatelessWidget {
  final notificationService = GetIt.instance.get<NotificationService>();
  final persistence = GetIt.instance.get<Persistence>();

  final Action action;
  final Widget body;

  ActionDetailsScreen({
    super.key,
    required this.action,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PokeAppBar(context),
        body: Column(
          children: [
            body,
            PokeConstants.FixedSpacer(),
            PokeButton.primaryDangerous(
              text: "Delete action",
              onPressed: () => _deleteAction(context),
            ),
            PokeConstants.FixedSpacer(),
            PokeFutureBuilder<ScheduledNotification?>(
              future: asFuture(
                notificationService
                    .getScheduledNotificationForAction(action.equalityKey),
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

  _deleteAction(BuildContext context) {
    // create a holder for modal.dismiss once the modal object has been created
    Function? onceDeleted;

    final modal = PokeModal(
      child: Column(
        children: [
          PokeText("DANGEROUS"),
          PokeAsyncButton.primaryDangerous(
            text: "DELETE NOW",
            onPressed: () async {
              await persistence.deleteAction(action.equalityKey);

              if (onceDeleted == null) {
                PokeLogger.instance().warn(
                  "unable to dismiss delete action modal because `onceDeleted` is null",
                  data: {
                    "actionId": action.equalityKey,
                  },
                );
              } else {
                onceDeleted();
              }

              // Take the user back home
              NavService.reset(HomeScreen());
            },
          ),
        ],
      ),
    );
    onceDeleted = modal.dismiss;

    modal.show(context);
  }
}
