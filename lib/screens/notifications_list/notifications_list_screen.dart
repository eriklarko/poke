import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/persistence.dart';

class NotificationsListScreen extends StatelessWidget {
  final notificationService = GetIt.instance.get<NotificationService>();
  final persistence = GetIt.instance.get<Persistence>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PokeAppBar(context),
      body: PokeFutureBuilder(
        future: notificationService.getAllScheduledNotifications(),
        child: (Iterable<(String, DateTime)> notifications) {
          // sort by action id to group notifications by action
          final sorted = notifications.sorted((a, b) {
            final actionIdCmp = a.$1.compareTo(b.$1);
            if (actionIdCmp == 0) {
              return a.$2.compareTo(b.$2);
            }
            return actionIdCmp;
          });

          return ListView(
            children: sorted
                .map((notification) => buildNotificationWidget(notification))
                .toList(),
          );
        },
      ),
    );
  }

  Widget buildNotificationWidget((String, DateTime) notification) {
    final actionId = notification.$1;
    final scheduledAt = notification.$2;

    return PokeFutureBuilder(
      future: persistence.getAction(actionId),
      child: (action) {
        if (action == null) {
          return PokeText('Action $actionId not found');
        }

        return ListTile(
          title: PokeText(
            action.toString(),
          ),
          subtitle: PokeText(
            scheduledAt.toString(),
          ),
        );
      },
    );
  }
}
