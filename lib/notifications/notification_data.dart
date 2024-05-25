class NotificationData {
  final String title;
  final String body;
  final String? bigPictureUrl;
  final bool persistentWhenOverdue;

  NotificationData({
    required this.title,
    required this.body,
    this.bigPictureUrl,
    this.persistentWhenOverdue = false,
  });
}
