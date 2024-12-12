import 'package:get_it/get_it.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';

Future<void> logAction<TEventData extends SerializableEventData?>(
  Action<TEventData> action,
  DateTime when, {
  TEventData? eventData,
}) async {
  // Log the action
  await GetIt.instance
      .get<Persistence>()
      .logAction(action, when, eventData: eventData);

  // and cancel any scheduled or currently showing notifications
  await GetIt.instance
      .get<NotificationService>()
      .cancelScheduledNotificationForAction(action.equalityKey);
}
