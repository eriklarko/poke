import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/services/log_action.dart';

import '../notifications/in_memory_notification_platform.dart';
import '../utils/dependencies.dart';
import '../utils/test-action/test_action.dart';

void main() {
  registerTestActions();
  test('logs action', () async {
    setNotificationService();
    /////

    final persistence = InMemoryPersistence();
    setPersistence(persistence);

    final action = TestAction();
    await persistence.createAction(action);

    final ts = DateTime.parse('1963-11-26');
    await logAction(action, ts);

    final events = (await persistence.getAction(action.equalityKey))?.events;
    expect(
      events?.keys,
      [ts],
    );
  });

  test('updates notification', () async {
    // set up action to be reminded of at X
    final persistence = InMemoryPersistence();
    final action = TestAction().withEvents({
      DateTime.parse('1963-11-26'): null,
      DateTime.parse('1989-12-06'): null,
    });

    await persistence.createAction(action);
    setPersistence(persistence);

    // schedule notification for the action
    await setReminderService();
    final notifService = setNotificationService();
    await notifService.initialize();
    await notifService.setUpReminderNotifications();

    final firstNotif = await notifService.getScheduledNotificationForAction(
      action.equalityKey,
    );

    // log new event
    await persistence.logAction(action, DateTime.parse('2005-03-26'));
    await pumpEventQueue();

    final secondNotif = await notifService.getScheduledNotificationForAction(
      action.equalityKey,
    );

    expect(firstNotif?.$2, isNot(equals(secondNotif?.$2)));
  });

  test('dismisses active notification', () async {
    await setReminderService();
    final notifService = setNotificationService();
    await notifService.initialize();

    var action = TestAction();
    final dueDate = DateTime.now().add(Duration(hours: 1));
    await notifService.scheduleReminder(action, dueDate);

    // move time forward
    final platform =
        AwesomeNotificationsPlatform.instance as InMemoryNotificationPlatform;
    await platform.processScheduledNotifications(
      dueDate.add(Duration(seconds: 1)),
    );

    // ensure notification is showing
    expect(await notifService.getActiveNotifications(), [action.equalityKey]);

    // log event to dismiss notification
    await logAction(action, DateTime.parse("1963-11-26"));
    await pumpEventQueue();

    expect(await notifService.getActiveNotifications(), []);
  });
}
