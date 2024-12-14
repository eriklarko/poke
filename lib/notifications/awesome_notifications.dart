import 'dart:async';
import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_data.dart';
import 'package:poke/persistence/device_persistence.dart';
import 'package:poke/reminder_service/reminder_service.dart';
import "package:collection/collection.dart";

import 'notification_service.dart';

class AwesomeNotificationsService extends NotificationService {
  static const permissionResponseKey = "POKE_ALLOW_NOTIFICATIONS";
  static const permissionResponseYes = "yes";
  static const permissionResponseNo = "no";

  final _i = AwesomeNotifications();
  final _deviceSettings = GetIt.instance.get<DevicePersistence>();

  StreamSubscription<ReminderUpdate>? _remindersListener;

  @override
  Future<void> initialize() async {
    await _i.initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription:
              'Used during notification setup, not for sending actual notifications',
        ),
      ],
      // Channel groups are only visual and are not required
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Basic group',
        )
      ],
      debug: kDebugMode,
    );

    // Only after at least the action method is set, the notification events are delivered
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );

    _remindersListener = GetIt.instance
        .get<ReminderService>()
        .updatesStream()
        .listen((event) async {
      switch (event.type) {
        case UpdateType.updating:
          // nothing to do here
          break;
        case UpdateType.added:
        case UpdateType.updated:
          final reminder = event.reminder;
          if (reminder == null) {
            return;
          }

          if (reminder.dueDate == null) {
            // cancel any scheduled notification for this action
            await cancelScheduledNotificationForAction(
              reminder.action.equalityKey,
            );
            // remove any active notification for this action
            // TODO: Test
            await _i.dismiss(_getNotificationId(reminder.action));
            return;
          }

          final permission = await hasPermissionToSendNotifications();
          if (permission == PermissionResponse.allowed) {
            await scheduleReminder(reminder.action, reminder.dueDate!);
          }

        case UpdateType.removed:
          print("awesome_notifications got removed event: ${event}");
          cancelScheduledNotificationForAction(event.actionId);
        default:
          PokeLogger.instance().warn(
            "awesome_notifications got an unknown event type",
            data: {
              'event': event,
            },
          );
      }
    });
  }

  @override
  FutureOr<void> dispose() {
    _remindersListener?.cancel();
  }

  // TODO: test when internal storage and AwesomeNotifications don't agree
  // This method uses internal storage to record the user's response so that
  // PermissionResponse.hasNotChosen can be correctly derived.
  // AwesomeNotifications stores a bool and can thus not distinguish from a
  // user having denied notifications or if they haven't chosen yet.
  @override
  FutureOr<PermissionResponse> hasPermissionToSendNotifications() async {
    final persistedDecision = await _deviceSettings.get(permissionResponseKey);
    final allowed = await _i.isNotificationAllowed();

    if (persistedDecision == null && allowed) {
      // internal storage says user hasn't chosen, but AwesomeNotifications says
      // the user has.
      // update internal storage
      await _deviceSettings.set(permissionResponseKey, permissionResponseYes);
      return PermissionResponse.allowed;
    }

    if (persistedDecision == null) {
      // internal storage says user hasn't chosen, and AwesomeNotifcations says
      // permission is denied. Since denied is the default we cannot know if the
      // user has decied or not yet, so we assume they haven't
      return PermissionResponse.hasNotChosen;
    }

    final persistedBool = persistedDecision == permissionResponseYes;
    if (allowed && !persistedBool) {
      // user has allowed notifications, but the internal storage says no
      // update internal storage
      await _deviceSettings.set(permissionResponseKey, permissionResponseYes);
      return PermissionResponse.allowed;
    }

    if (!allowed && persistedBool) {
      // user has denied notifications, but the internal storage says yes
      // update insternal storage
      await _deviceSettings.set(permissionResponseKey, permissionResponseNo);
      return PermissionResponse.denied;
    }

    // if we reach this, AwesomeNotifications and internal storage agrees
    return allowed ? PermissionResponse.allowed : PermissionResponse.denied;
  }

  @override
  Future<void> decidePermissionsToSendNotifications() async {
    final gavePermission = await _i.requestPermissionToSendNotifications();
    return await _recordPermissionAnswer(gavePermission);
  }

  Future<void> _recordPermissionAnswer(bool gavePermission) async {
    PokeLogger.instance().info(
      gavePermission
          ? "User gave permission to send notifications"
          : "User denied permission to send notifications",
    );

    await _deviceSettings.set(
      permissionResponseKey,
      gavePermission ? permissionResponseYes : permissionResponseNo,
    );
  }

  @override
  FutureOr<void> scheduleReminder(Action action, DateTime dueDate) async {
    await _i.dismiss(_getNotificationId(action));

    final existingReminder = await getScheduledNotificationForAction(
      action.equalityKey,
    );
    if (existingReminder != null) {
      PokeLogger.instance().info(
        "Scheduled reminder found, removing it and creating a new one",
        data: {
          'action': action,
          'existingDueDate': existingReminder.$2,
          'newDueDate': dueDate,
        },
      );

      // updating here means deleting the old reminder and creating a new one :)
      await cancelScheduledNotificationForAction(action.equalityKey);
    }

    await _ensureChannelExists(action);
    final actionData = action.getNotificationData();

    await _i.createNotification(
      content: _createNotificationContent(
        action,
        actionData,
        dueDate,
      ),
      schedule: _createScheduleFromDueDate(dueDate),
      actionButtons: actionData.actionButtons,
    );
  }

  NotificationSchedule _createScheduleFromDueDate(DateTime dueDate) {
    // notifications are not created if they're scheduled in the past, but we
    // want notifications to show up even if the due date has passed, so here we
    // make sure the notification is scheduled in the future
    final now = clock.now();
    if (dueDate.isBefore(now)) {
      return NotificationCalendar.fromDate(
        date: now.add(const Duration(seconds: 1)),
      );
    }

    return NotificationCalendar.fromDate(
      date: dueDate,
    );
  }

  Future<void> _ensureChannelExists(Action action) async {
    await _i.setChannel(
      NotificationChannel(
        channelKey: _getChannelKey(action),
        channelName: "${action.equalityKey} notifications",
        channelDescription: "Notifications for ${action.equalityKey}",
        channelGroupKey: _getChannelGroup(action),
      ),
    );
  }

  String _getChannelKey(Action action) {
    return "notification-channel-${action.equalityKey}";
  }

  String _getChannelGroup(Action action) {
    return "notification-channel-group-${action.getSerializationKey()}";
  }

  NotificationContent _createNotificationContent(
    Action action,
    NotificationData actionData,
    DateTime scheduleDate,
  ) {
    return NotificationContent(
      id: _getNotificationId(action),
      channelKey: _getChannelKey(action),
      actionType: ActionType.Default,
      title: actionData.title,
      body: actionData.body,
      payload: {
        'action-id': action.equalityKey,
        // There's nothing in the AweomseNotifications API to get the date when
        // a notification was scheduled, so because it's used in the app it must
        // be set here :(
        'when': scheduleDate.toIso8601String(),
      },
      bigPicture: actionData.bigPictureUrl,
      autoDismissible:
          actionData.persistentWhenOverdue && clock.now().isAfter(scheduleDate),
    );
  }

  int _getNotificationId(Action action) {
    return _getNotificationIdFromActionId(action.equalityKey);
  }

  int _getNotificationIdFromActionId(String actionId) {
    // generate data unique to the action
    final uniqueData = actionId;

    // convert it to a hash
    final hash = md5.convert(uniqueData.codeUnits);
    final hashBytes = Int8List.fromList(hash.bytes);

    // awesomenotifications says id must be in range
    // [1, 2,147,483,647] = [1 - 2^31]. 2,147,483,647 is the max value for a
    // signed 32-bit integer, so we can take the first four bytes of the hash as
    // a 32-bit int, and abs it.
    //
    // To avoid 0, return 1 if hash is 0. this is a collision, but there are
    // already collisions possible
    final id = hashBytes.buffer.asByteData().getInt32(0).abs();
    if (id == 0) {
      return 1;
    }
    return id;
  }

  @override
  FutureOr<Iterable<ScheduledNotification>>
      getAllScheduledNotifications() async {
    final notifications = await _i.listScheduledNotifications();
    return _mapExternalModelFromInternal(notifications);
  }

  Iterable<ScheduledNotification> _mapExternalModelFromInternal(
    Iterable<NotificationModel> notifications,
  ) {
    return notifications.map((notification) {
      final payload = notification.content!.payload!;
      if (!payload.containsKey('action-id')) {
        return null;
      }

      return (payload['action-id']!, DateTime.parse(payload['when']!));
    }).whereNotNull();
  }

  @override
  FutureOr<ScheduledNotification?> getScheduledNotificationForAction(
    String actionId,
  ) async {
    final allNotifications = await getAllScheduledNotifications();

    return allNotifications.firstWhereOrNull(
      (tuple) => tuple.$1 == actionId,
    );
  }

  FutureOr<Iterable<String>> getActiveNotifications() async {
    final notifications = await _i.listScheduledNotifications();
    final activeNotificationIds =
        await _i.getAllActiveNotificationIdsOnStatusBar();

    final activeNotifications = notifications.where(
      (notification) =>
          activeNotificationIds.contains(notification.content!.id!),
    );

    return activeNotifications
        .map((notification) => notification.content?.payload?['action-id'])
        .whereNotNull();
  }

  @override
  FutureOr<void> removeAllReminders() {
    return _i.cancelAllSchedules();
  }

  @override
  FutureOr<void> cancelScheduledNotificationForAction(String actionId) async {
    final notifs = await getAllScheduledNotifications();
    final hasScheduledNotification =
        notifs.any((tuple) => tuple.$1 == actionId);

    if (hasScheduledNotification) {
      await _i.cancelSchedule(_getNotificationIdFromActionId(actionId));
    }
  }

  ///////////////////////////////
  /// You need to use @pragma("vm:entry-point") in each static method to
  /// identify to the Flutter engine that the dart address will be called from
  /// native and should be preserved.

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here

    PokeLogger.instance().debug(
      "onNotificationCreatedMethod",
      data: {
        'notification': receivedNotification,
      },
    );
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here

    PokeLogger.instance().debug(
      "onNotificationDisplayedMethod",
      data: {
        'notification': receivedNotification,
      },
    );
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here

    PokeLogger.instance().debug(
      "onDismissActionReceivedMethod",
      data: {
        'action': receivedAction,
      },
    );
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Your code goes here
    // TODO: NotificationActionButtons end up here. Route them back to whatever listener they need to go to

    PokeLogger.instance().debug(
      "onActionReceivedMethod",
      data: {
        'action': receivedAction,
      },
    );
  }
}
