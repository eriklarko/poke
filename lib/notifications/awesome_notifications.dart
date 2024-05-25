import 'dart:async';
import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/persistence/device_persistence.dart';
import 'package:poke/reminder_service/reminder_service.dart';
import "package:collection/collection.dart";

import 'notification_service.dart';

class AwesomeNotificationsService extends NotificationService {
  static const _permissionResponseKey = "POKE_ALLOW_NOTIFICATIONS";

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

    _remindersListener =
        GetIt.instance.get<ReminderService>().updatesStream().listen((event) {
      switch (event.type) {
        case UpdateType.added:
        case UpdateType.updated:
          final reminder = event.reminder;
          if (reminder == null) {
            return;
          }

          if (reminder.dueDate == null) {
            // nothing to schedule because there's no  due date
            return;
          }

          scheduleReminder(reminder.action, reminder.dueDate!);
        default:
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
    final persistedDecision = await _deviceSettings.get(_permissionResponseKey);
    final allowed = await _i.isNotificationAllowed();

    if (persistedDecision == null && allowed) {
      // internal storage says user hasn't chosen, but AwesomeNotifications says
      // the user has.
      // update internal storage
      await _deviceSettings.set(_permissionResponseKey, "yes");
      return PermissionResponse.allowed;
    }

    if (persistedDecision == null) {
      // internal storage says user hasn't chosen, and AwesomeNotifcations says
      // permission is denied. Since denied is the default we cannot know if the
      // user has decied or not yet, so we assume they haven't
      return PermissionResponse.hasNotChosen;
    }

    final persistedBool = persistedDecision == "yes";
    if (allowed && !persistedBool) {
      // user has allowed notifications, but the internal storage says no
      // update internal storage
      await _deviceSettings.set(_permissionResponseKey, "yes");
      return PermissionResponse.allowed;
    }

    if (!allowed && persistedBool) {
      // user has denied notifications, but the internal storage says yes
      // update insternal storage
      await _deviceSettings.set(_permissionResponseKey, "no");
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
      _permissionResponseKey,
      gavePermission ? "yes" : "no",
    );
  }

  @override
  FutureOr<void> scheduleReminder(Action action, DateTime dueDate) async {
    await _ensureChannelExists(action);
    await _i.createNotification(
      content: _createNotificationContent(
        action,
        dueDate,
      ),
      schedule: NotificationCalendar.fromDate(date: dueDate),
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
    DateTime scheduleDate,
  ) {
    final actionData = action.getNotificationData();
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
        'when': scheduleDate?.toIso8601String(),
      },
      bigPicture: actionData.bigPictureUrl,
      autoDismissible:
          actionData.persistentWhenOverdue && clock.now().isAfter(scheduleDate),
    );
  }

  int _getNotificationId(Action action) {
    // generate data unique to the action
    final uniqueData = action.equalityKey;

    // convert it to a hash
    final hash = md5.convert(uniqueData.codeUnits);
    final hashBytes = Int8List.fromList(hash.bytes);

    // and take the first four bytes in the hash
    return hashBytes.buffer.asByteData().getInt32(0);
  }

  @override
  FutureOr<Iterable<(String /*action id*/, DateTime)>>
      getAllScheduledNotifications() async {
    final notifications = await _i.listScheduledNotifications();
    return notifications.map((notification) {
      final payload = notification.content!.payload!;
      if (!payload.containsKey('action-id')) {
        return null;
      }

      return (payload['action-id']!, DateTime.parse(payload['when']!));
    }).whereNotNull();
  }

  @override
  FutureOr<void> removeAllReminders() {
    return _i.cancelAllSchedules();
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

    PokeLogger.instance().debug(
      "onActionReceivedMethod",
      data: {
        'action': receivedAction,
      },
    );
  }
}
