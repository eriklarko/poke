import 'dart:async';

import 'package:calendar_view/calendar_view.dart';
import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/design_system/poke_time_ago.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/persistence.dart';

class NotificationsListScreen extends StatelessWidget {
  final notificationService = GetIt.instance.get<NotificationService>();
  final persistence = GetIt.instance.get<Persistence>();

  NotificationsListScreen({super.key});

  FutureOr<Iterable<(Action, DateTime)>> fetchScheduledNotifications() async {
    final notifs = await notificationService.getAllScheduledNotifications();
    final toReturn = <(Action, DateTime)>[];
    for (final notif in notifs) {
      final actionId = notif.$1;
      final scheduledAt = notif.$2;

      final action = await persistence.getAction(actionId);
      if (action == null) {
        PokeLogger.instance().error('Action not found', data: {
          'actionId': actionId,
        });
        continue;
      }

      toReturn.add((action, scheduledAt));
    }

    return toReturn;
  }

  Iterable<(T, DateTime)> sortDateAsc<T>(
    Iterable<(T, DateTime)> notifications,
  ) {
    return notifications.sorted((a, b) {
      return a.$2.compareTo(b.$2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PokeAppBar(context),
      body: PokeFutureBuilder(
        future: fetchScheduledNotifications(),
        child: (Iterable<(Action, DateTime)> notifications) {
          final ec = EventController<Action>();
          ec.addAll(
            notifications
                .map(
                  (e) => CalendarEventData<Action>(
                    title: e.$1.getHumanReadableName(),
                    date: e.$2,
                    color: hashToColor(e.$1.equalityKey.hashCode),
                    event: e.$1,
                  ),
                )
                .toList(),
          );

          final sorted = sortDateAsc(notifications);
          return MonthView(
            controller: ec,
            minMonth: sorted.firstOrNull?.$2,
            initialMonth: clock.now(),
            onCellTap: (events, date) {
              openDayModal(context, date, events.map((cea) => cea.event!));
            },
            onEventTap: (event, date) {
              openEventModal(context, event.event!, date);
            },
          );
        },
      ),
    );
  }

  Color hashToColor(int hashCode) {
    const colors = [
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.amber,
      Colors.deepOrange,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.lime,
      Colors.black,
    ];
    return colors[hashCode % colors.length];
  }

  void openDayModal(
    BuildContext context,
    DateTime date,
    Iterable<Action> events,
  ) {
    final m = PokeModal(
      child: Column(
        children: [
          PokeText("Events on ${date.toIso8601String()}"),
          PokeConstants.FixedSpacer(2),
          ...events.map((action) => PokeText(action.getHumanReadableName())),
        ],
      ),
    );
    m.show(context);
  }

  void openEventModal(BuildContext context, Action action, DateTime dueDate) {
    final m = PokeModal(
      child: Column(
        children: [
          PokeText("Notification for ${action.getHumanReadableName()}"),
          PokeText("scheduled: "),
          PokeTimeAgo(date: dueDate),
        ],
      ),
    );
    m.show(context);
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
          title: PokeText(action.getHumanReadableName()),
          subtitle: PokeTimeAgo(
            date: scheduledAt,
            format: (formattedTime) => "Scheduled: $formattedTime",
          ),
        );
      },
    );
  }
}
