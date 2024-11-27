import 'package:flutter/widgets.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/utils/future_helpers.dart';

class NotificationIndicator extends StatelessWidget {
  final notificationService = GetIt.instance.get<NotificationService>();
  final Action action;

  NotificationIndicator({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return PokeFutureBuilder<ScheduledNotification?>(
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
        });
  }
}
