import 'dart:async';

import 'package:clock/clock.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/models/action.dart';
import 'package:poke/reminder_service/reminder_service.dart';

abstract class NotificationService {
  FutureOr<void> initialize();

  FutureOr<void> dispose();

  FutureOr<PermissionResponse> hasPermissionToSendNotifications();

  FutureOr<void> decidePermissionsToSendNotifications();

  FutureOr<void> scheduleReminder(Action action, DateTime dueDate);

  FutureOr<void> setUpReminderNotifications() async {
    await removeAllReminders();

    final allReminders = GetIt.instance.get<ReminderService>().getReminders();
    final futures = allReminders
        // filter out those without due dates
        .where((reminder) => reminder.dueDate != null)
        // filter out past ones
        .where((reminder) => reminder.dueDate!.isAfter(clock.now()))
        // schedule notifications for all reminders with due dates
        .map(
          (reminder) => scheduleReminder(reminder.action, reminder.dueDate!),
        )
        // and keep any futures from `scheduleReminder` so we can `wait` on them later
        .whereType<Future>();

    // wait for all `scheduleReminder` futures to finish
    await Future.wait(futures);
  }

  FutureOr<void> removeAllReminders();

  FutureOr<Iterable<(String /* action id */, DateTime)>>
      getAllScheduledNotifications();
}

enum PermissionResponse {
  hasNotChosen,
  allowed,
  denied,
}
