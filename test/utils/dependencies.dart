import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/notifications/awesome_notifications.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/device_persistence.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/predictor/predictor.dart';
import 'package:poke/predictor/time_of_day_aware_average_predictor.dart';
import 'package:poke/reminder_service/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/in_memory_notification_platform.dart';

void setPersistence(Persistence persistence) {
  setDependency<Persistence>(persistence);
}

DevicePersistence setUpDevicePersistence([
  DevicePersistence? existingPersistence,
]) {
  final p = existingPersistence ?? DevicePersistence();
  if (existingPersistence == null) {
    // reset internal storage
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
  }
  setDependency<DevicePersistence>(p);

  return p;
}

void setDependency<T extends Object>(T t) {
  GetIt.instance.allowReassignment = true;
  GetIt.instance.registerSingleton<T>(t);
}

Future<void> setReminderService([
  bool createDeps = true,
  ReminderService? reminderService,
]) async {
  if (createDeps) {
    if (!GetIt.instance.isRegistered<Predictor>()) {
      setDependency<Predictor>(TimeOfDayAwareAveragePredictor());
    }

    if (!GetIt.instance.isRegistered<Persistence>()) {
      setDependency<Persistence>(InMemoryPersistence());
    }
  }

  reminderService ??= ReminderService();
  await reminderService.init();
  setDependency<ReminderService>(reminderService);
}

void setNotificationService() {
  setUpDevicePersistence();
  AwesomeNotificationsPlatform.instance = InMemoryNotificationPlatform();
  setDependency<NotificationService>(AwesomeNotificationsService());
}
