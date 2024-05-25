import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationData {
  final String title;
  final String body;
  final String? bigPictureUrl;
  final List<NotificationActionButton>? actionButtons;
  final bool persistentWhenOverdue;

  NotificationData({
    required this.title,
    required this.body,
    this.bigPictureUrl,
    this.actionButtons,
    this.persistentWhenOverdue = false,
  });
}
