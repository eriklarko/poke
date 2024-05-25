import 'dart:typed_data';
import 'package:clock/clock.dart';
import 'package:fixnum/fixnum.dart';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';

typedef NotificationId = int;

class InMemoryNotificationPlatform extends AwesomeNotificationsPlatform {
  final Map<NotificationId, NotificationModel> _notifications = {};
  final Map<NotificationChannel, List<NotificationId>> _channels = {};
  bool _canSendNotifications = false;

  InMemoryNotificationPlatform();

  @override
  Future<void> cancel(int id) {
    _notifications.remove(id);
    for (var notificationIds in _channels.values) {
      notificationIds.remove(id);
    }
    return Future.value(null);
  }

  @override
  Future<void> cancelAll() {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelAllSchedules() async {
    for (final notification in await listScheduledNotifications()) {
      if (notification.schedule != null) {
        await cancel(notification.content!.id!);
      }
    }
  }

  @override
  Future<void> cancelNotificationsByChannelKey(String channelKey) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelNotificationsByGroupKey(String groupKey) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelSchedule(int id) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelSchedulesByChannelKey(String channelKey) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelSchedulesByGroupKey(String groupKey) {
    throw UnimplementedError();
  }

  @override
  Future<List<NotificationPermission>> checkPermissionList(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> createNotification({
    required NotificationContent content,
    NotificationSchedule? schedule,
    List<NotificationActionButton>? actionButtons,
    Map<String, NotificationLocalization>? localizations,
  }) {
    if (!_is32Bit(content.id!)) {
      throw "id must be 32 bit";
    }

    if (!_channels.keys
        .any((channel) => channel.channelKey == content.channelKey)) {
      throw "channel ${content.channelKey} does not exist";
    }

    // Mimic AwesomeNotifications' platforms that reject schedules in the past
    if (schedule is NotificationCalendar &&
        _toDate(schedule).isBefore(clock.now())) {
      print("notification ignored because it is scheduled in the past");
      return Future.value(false);
    }

    final notif = NotificationModel(
      content: content,
      schedule: schedule,
      actionButtons: actionButtons,
      localizations: localizations,
    );

    _notifications.update(
      content.id!,
      (value) => notif,
      ifAbsent: () => notif,
    );

    return Future.value(true);
  }

  DateTime _toDate(NotificationCalendar c) {
    return DateTime(
      c.year ?? 0,
      c.month ?? 0,
      c.day ?? 0,
      c.hour ?? 0,
      c.minute ?? 0,
      c.second ?? 0,
    );
  }

  bool _is32Bit(int i) {
    // Int32(i) keeps only the lowest four bits of `i`; if `i` is greater than
    // 32 bits that'll result in a different int than `i`.
    return Int32(i) == i;
  }

  @override
  Future<bool> createNotificationFromJsonData(Map<String, dynamic> mapData) {
    throw UnimplementedError();
  }

  @override
  Future<int> decrementGlobalBadgeCounter() {
    throw UnimplementedError();
  }

  @override
  Future<void> dismiss(int id) {
    throw UnimplementedError();
  }

  @override
  Future<void> dismissAllNotifications() {
    throw UnimplementedError();
  }

  @override
  Future<void> dismissNotificationsByChannelKey(String channelKey) {
    throw UnimplementedError();
  }

  @override
  Future<void> dismissNotificationsByGroupKey(String groupKey) {
    throw UnimplementedError();
  }

  @override
  dispose() {
    throw UnimplementedError();
  }

  @override
  Future<List<int>> getAllActiveNotificationIdsOnStatusBar() {
    throw UnimplementedError();
  }

  @override
  Future<NotificationLifeCycle> getAppLifeCycle() {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List?> getDrawableData(String drawablePath) {
    throw UnimplementedError();
  }

  @override
  Future<int> getGlobalBadgeCounter() {
    throw UnimplementedError();
  }

  @override
  Future<ReceivedAction?> getInitialNotificationAction(
      {bool removeFromActionEvents = false}) {
    throw UnimplementedError();
  }

  @override
  Future<String> getLocalTimeZoneIdentifier() {
    throw UnimplementedError();
  }

  @override
  Future<String> getLocalization() {
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> getNextDate(NotificationSchedule schedule,
      {DateTime? fixedDate}) {
    throw UnimplementedError();
  }

  @override
  Future<String> getUtcTimeZoneIdentifier() {
    throw UnimplementedError();
  }

  @override
  Future<int> incrementGlobalBadgeCounter() {
    throw UnimplementedError();
  }

  @override
  Future<bool> initialize(
      String? defaultIcon, List<NotificationChannel> channels,
      {List<NotificationChannelGroup>? channelGroups,
      bool debug = false,
      String? languageCode}) {
    return Future.value(true);
  }

  @override
  Future<bool> isNotificationActiveOnStatusBar({required int id}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isNotificationAllowed() {
    return Future.value(_canSendNotifications);
  }

  @override
  Future<List<NotificationModel>> listScheduledNotifications() {
    final scheduledNotifications = _notifications.values
        .where((notification) => notification.schedule != null)
        .toList();

    return Future.value(scheduledNotifications);
  }

  @override
  Future<bool> removeChannel(String channelKey) {
    throw UnimplementedError();
  }

  @override
  Future<bool> requestPermissionToSendNotifications(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]}) {
    _canSendNotifications = true;
    return Future.value(true);
  }

  @override
  Future<void> resetGlobalBadge() {
    throw UnimplementedError();
  }

  @override
  Future<void> setChannel(NotificationChannel notificationChannel,
      {bool forceUpdate = false}) {
    if (forceUpdate) {
      throw UnimplementedError();
    }

    if (!_channels.containsKey(notificationChannel)) {
      _channels[notificationChannel] = [];
    }

    return Future.value(null);
  }

  @override
  Future<void> setGlobalBadgeCounter(int amount) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setListeners(
      {required ActionHandler onActionReceivedMethod,
      NotificationHandler? onNotificationCreatedMethod,
      NotificationHandler? onNotificationDisplayedMethod,
      ActionHandler? onDismissActionReceivedMethod}) {
    return Future.value(true);
  }

  @override
  Future<bool> setLocalization({required String? languageCode}) {
    throw UnimplementedError();
  }

  @override
  Future<List<NotificationPermission>> shouldShowRationaleToRequest(
      {String? channelKey,
      List<NotificationPermission> permissions = const [
        NotificationPermission.Badge,
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
        NotificationPermission.Light
      ]}) {
    throw UnimplementedError();
  }

  @override
  Future<void> showAlarmPage() {
    throw UnimplementedError();
  }

  @override
  Future<void> showGlobalDndOverridePage() {
    throw UnimplementedError();
  }

  @override
  Future<void> showNotificationConfigPage({String? channelKey}) {
    throw UnimplementedError();
  }
}
