import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/notifications/awesome_notifications.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:clock/clock.dart';

import '../components/reminder_list/reminder_list_test.dart';
import '../utils/dependencies.dart';
import '../utils/test-action/test_action.dart';
import 'in_memory_notification_platform.dart';

final Iterable<
    (NotificationService, InMemoryNotificationPlatform) Function([
      InMemoryNotificationPlatform? platform,
    ])> constructors = [
  ([platform]) {
    if (platform == null) {
      // Set up device-level persistence for storing the user's choice
      setUpDevicePersistence();
    }
    final p = platform ?? InMemoryNotificationPlatform();
    AwesomeNotificationsPlatform.instance = p;

    return (AwesomeNotificationsService(), p);
  }
];

void main() {
  registerTestActions();

  test('false positives avoided by not testing any implementations', () {
    expect(constructors, isNotEmpty);
  });

  for (final constructor in constructors) {
    group('${constructor().runtimeType}', () {
      test('decidePermission gives permission across instances', () async {
        await setReminderService();

        final (sut, platform) = constructor();
        await sut.initialize();

        // first check that permission is not given, or else the test is moot
        expect(
          await sut.hasPermissionToSendNotifications(),
          equals(PermissionResponse.hasNotChosen),
        );

        await sut.decidePermissionsToSendNotifications();
        expect(
          await sut.hasPermissionToSendNotifications(),
          equals(PermissionResponse.allowed),
        );

        // check that a new instance remembers the decision
        final (sut2, _) = constructor(platform);
        await sut2.initialize();
        expect(
          await sut2.hasPermissionToSendNotifications(),
          equals(PermissionResponse.allowed),
        );
      });

      test('scheduleReminder only schedules one notification per action',
          () async {
        final (sut, _) = constructor();
        final action = TestAction(id: '1');

        final firstDueDate = DateTime.parse('1963-11-23');
        final secondDueDate = DateTime.parse('1989-12-06');

        await sut.scheduleReminder(action, firstDueDate);
        await sut.scheduleReminder(action, secondDueDate);

        expect(
          await sut.getAllScheduledNotifications(),
          equals([
            (action.equalityKey, secondDueDate),
          ]),
        );
      });

      test(
          'notification is scheduled when action has enough data for a due date',
          () async {
        // set up persistence and reminder service
        final persistence = InMemoryPersistence();
        setDependency<Persistence>(persistence);
        await setReminderService();

        // create the test action
        final action = TestAction(id: '1');

        final (sut, p) = constructor();
        await p.requestPermissionToSendNotifications();
        await sut.initialize();

        // not enough data yet
        await persistence.createAction(action);
        await pumpEventQueue();
        expect(
          await sut.getAllScheduledNotifications(),
          equals([]),
        );

        // still not enough data
        await persistence.logAction(action, DateTime.parse("1963-11-23"));
        await pumpEventQueue();
        expect(
          await sut.getAllScheduledNotifications(),
          equals([]),
        );

        // finally enough data
        await persistence.logAction(action, DateTime.parse("1989-12-06"));
        await pumpEventQueue();

        // assert that there is only one notification and that it's a reminder
        // for the test action
        final scheduledNotifications = await sut.getAllScheduledNotifications();
        expect(scheduledNotifications, hasLength(1));
        expect(
          scheduledNotifications.first.$1,
          equals(action.equalityKey),
        );
      });

      test('notification is scheduled when action due date changes', () async {
        final persistence = InMemoryPersistence();
        setDependency<Persistence>(persistence);
        await setReminderService();

        final action = TestAction(id: '1');

        final (sut, p) = constructor();
        await p.requestPermissionToSendNotifications();
        await sut.initialize();

        // create action and provide enough data for a due date
        await persistence.createAction(action);
        await persistence.logAction(action, DateTime.parse("1963-11-23"));
        await persistence.logAction(action, DateTime.parse("1989-12-06"));
        await pumpEventQueue();

        final firstDueDate =
            (await sut.getAllScheduledNotifications()).first.$2;

        // add more data so that the due date changes
        await persistence.logAction(action, DateTime.parse("2005-03-26"));
        await pumpEventQueue();
        final secondDueDate =
            (await sut.getAllScheduledNotifications()).first.$2;

        expect(
          secondDueDate,
          isNot(equals(firstDueDate)),
        );
      });

      test('notification removed when action is removed', () async {
        final persistence = InMemoryPersistence();
        setDependency<Persistence>(persistence);
        await setReminderService();

        final (sut, _) = constructor();
        await sut.initialize();

        // schedule a reminder fo the action
        final action = TestAction(id: '1');
        await sut.scheduleReminder(action, DateTime.parse('1963-11-23'));

        // remove the action
        await persistence.deleteAction(action.equalityKey);
        await pumpEventQueue();

        // assert that the reminder is gone
        expect(
          await sut.getAllScheduledNotifications(),
          isEmpty,
        );
      });

      test('active notification is dismissed when action is removed', () async {
        fail("not implemented yet");
      });

      test('active notification is dimissed when action is logged', () async {
        final persistence = InMemoryPersistence();
        setDependency<Persistence>(persistence);

        await setReminderService();
        final notifService = setNotificationService();
        await notifService.initialize();

        var action = TestAction();
        final dueDate = DateTime.now().add(Duration(hours: 1));
        await notifService.scheduleReminder(action, dueDate);

        // move time forward
        final platform = AwesomeNotificationsPlatform.instance
            as InMemoryNotificationPlatform;
        await platform.processScheduledNotifications(
          dueDate.add(Duration(seconds: 1)),
        );

        // ensure notification is showing
        expect(
          await notifService.getActiveNotifications(),
          [action.equalityKey],
        );

        // log event to dismiss notification
        await persistence.logAction(action, DateTime.parse("1963-11-26"));
        await pumpEventQueue();

        expect(await notifService.getActiveNotifications(), []);
      });

      test('schedules reminders for all actions with due dates', () async {
        // set up actions and due dates
        final a1 = TestAction(id: '1');
        final a2 = TestAction(id: '2');
        final a3 = TestAction(id: '3');

        final dt1 = DateTime.parse("1963-11-23");
        final dt2 = DateTime.parse("1989-12-06");

        // wire up dependencies to return reminders for the actions defined
        // above
        await setUpReminderServiceMock([
          Reminder(action: a1, dueDate: dt1),
          Reminder(action: a2, dueDate: dt2),
          Reminder(action: a3, dueDate: null),
        ]);
        final (sut, _) = constructor();

        // act
        await sut.setUpReminderNotifications();

        // assert
        expect(
          await sut.getAllScheduledNotifications(),
          equals([
            (a1.equalityKey, dt1),
            (a2.equalityKey, dt2),
          ]),
        );
      });

      // This test makes sure that notifications are sent even when the due date
      // has passed. This is important because the user might not have opened
      // the app for a while, and we still want to remind them of the action.
      test('schedules reminders even when the due date has passed', () async {
        final action = TestAction(id: '1');
        final dueDate = DateTime.parse("1963-11-23");

        await setUpReminderServiceMock([
          Reminder(action: action, dueDate: dueDate),
        ]);
        final (sut, _) = constructor();

        final dayAfterDueDate = dueDate.add(const Duration(days: 1));
        await withClock(Clock.fixed(dayAfterDueDate), () async {
          await sut.setUpReminderNotifications();
        });

        expect(
          await sut.getAllScheduledNotifications(),
          equals([
            (action.equalityKey, dueDate),
          ]),
        );
      });

      test('cleans up orphaned reminders when setting up reminders', () async {
        // wire up dependencies to return reminders for one action
        final a = TestAction(id: '1');
        final dueDate = DateTime.parse("1963-11-23");
        await setUpReminderServiceMock([
          Reminder(action: a, dueDate: dueDate),
        ]);
        final (sut, _) = constructor();

        // create orphaned notification by using an action that's not part of
        // the reminder service
        await sut.scheduleReminder(
          TestAction(id: '2'),
          DateTime.parse('1989-12-06'),
        );

        // act with a clock where the due date hasn't passed yet
        await withClock(Clock.fixed(dueDate.subtract(const Duration(days: 1))),
            () async {
          await sut.setUpReminderNotifications();
        });

        // assert orphaned notification is gone
        expect(
          await sut.getAllScheduledNotifications(),
          equals([
            (a.equalityKey, dueDate),
          ]),
        );
      });

      test('cancelScheduledNotificationForAction cancels notification',
          () async {
        // set up actions and due dates
        final a1 = TestAction(id: '1');
        final a2 = TestAction(id: '2');

        // wire up dependencies to return reminders for the actions defined
        // above
        await setUpReminderServiceMock([
          Reminder(action: a1, dueDate: DateTime.parse("1963-11-23")),
          Reminder(action: a2, dueDate: DateTime.parse("1989-12-06")),
        ]);
        final (sut, _) = constructor();
        await sut.setUpReminderNotifications();

        // act
        await sut.cancelScheduledNotificationForAction(a1.equalityKey);

        // assert
        expect(
          (await sut.getAllScheduledNotifications()).map((tuple) => tuple.$1),
          equals([
            a2.equalityKey,
          ]),
        );
      });

      test("can't cancel notification for action that doesn't exist", () async {
        final action = TestAction(id: '1');

        await setUpReminderServiceMock([
          Reminder(action: action, dueDate: null),
        ]);
        final (sut, _) = constructor();
        await sut.setUpReminderNotifications();

        // test doesn't throw if there's no notification to cancel
        await sut.cancelScheduledNotificationForAction(action.equalityKey);

        // test doesn't throw on non-existent action
        await sut.cancelScheduledNotificationForAction('non-existent-action');
      });
    });
  }
}
