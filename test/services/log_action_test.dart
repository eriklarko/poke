import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/services/log_action.dart';

import '../utils/dependencies.dart';
import '../utils/test-action/test_action.dart';

void main() {
  test('logs action', () async {
    registerTestActions();
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
    registerTestActions();

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

    // check that the notification is scheduled for the correct time
    // TODO

    // log new action
    // TODO

    // check that the notification is updated to the new time
    // TODO
    expect(
      (await notifService.getScheduledNotificationForAction(action.equalityKey))
          ?.$2,
      DateTime.parse("1989-12-07"),
    );
  });

  test('dismisses active notification', () async {
    fail('not implemented');
  });
}
