import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' hide Persistence;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logger/logger.dart';
import 'package:poke/logger/combined_logger.dart';
import 'package:poke/logger/google_cloud_logger.dart';
import 'package:poke/logger/local_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/awesome_notifications.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/device_persistence.dart';
import 'package:poke/persistence/persistence.dart';

import 'package:poke/persistence/firebase_firestore_persistence.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/predictor/predictor.dart';
import 'package:poke/predictor/time_of_day_aware_average_predictor.dart';
import 'package:poke/reminder_service/reminder_service.dart';

import 'package:poke/screens/auth/login_screen.dart';
import 'package:poke/screens/home_screen.dart';
import 'package:poke/screens/loading/poke_firebase.dart';
import 'package:poke/utils/nav_service.dart';
import 'package:uuid/uuid.dart';

Future initializeApp({
  PokeFirebase firebase = const PokeFirebase(),
  AuthClient? gcloudAuthClient,
  NavigatorState? nav,
}) async {
  await firebase.initializeApp();

  setupCrashHandlers(firebase);

  Action.registerSubclasses();

  await registerAppCheck(firebase);

  final gcloudLogger = await setUpGoogleCloudLogger(gcloudAuthClient);
  registerServices(firebase, gcloudLogger);

  registerFirebaseAuthListener(
    firebase,
    nav ?? NavService.instance,
  );
}

Future<void> registerAppCheck(PokeFirebase firebase) async {
  await firebase.appCheck().activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );
}

Future<GoogleCloudLogger> setUpGoogleCloudLogger(AuthClient? authClient) async {
  final gcloudLogger = GoogleCloudLogger(
    levels: [Level.debug, Level.info, Level.warning, Level.error, Level.fatal],
  );
  await gcloudLogger.initialize(authClient: authClient);
  return gcloudLogger;
}

void registerServices(PokeFirebase firebase, GoogleCloudLogger gcloudLogger) {
  final getIt = GetIt.instance;

  final allowReassignment = getIt.allowReassignment;
  try {
    // because of hot-reloading we need to allow reassignments in debug
    // restore this behavior in `finally`
    if (kDebugMode) {
      getIt.allowReassignment = true;
    }

    getIt.registerSingleton<Persistence>(
      FirebaseFirestorePersistence(firebase),
    );

    getIt.registerSingleton<DevicePersistence>(DevicePersistence());
    getIt.registerSingleton<NotificationService>(AwesomeNotificationsService());

    getIt.registerSingleton<PokeLogger>(
      CombinedLogger([
        LocalLogger(
          stackTraceBeginIndex: 10,
          methodCount: 14,
        ),
        gcloudLogger
      ]),
    );

    // this depencendy is use to generate uuids. The reason it's a dependency
    // like this is so that we can mock it in tests
    getIt.registerSingleton<Uuid>(const Uuid());

    getIt.registerSingleton<Predictor>(TimeOfDayAwareAveragePredictor());
    getIt.registerSingleton<ReminderService>(ReminderService());
  } finally {
    getIt.allowReassignment = allowReassignment;
  }
}

void setupCrashHandlers(PokeFirebase firebase) {
  // Gotta get the crashlytics handle outside the two onError functions for
  // mockito to work
  final crashlytics = firebase.crashlytics();

  final originalflutterError = FlutterError.onError;
  FlutterError.onError = (errorDetails) {
    originalflutterError?.call(errorDetails);

    crashlytics.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  final originalPlatformDispatcherError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    originalPlatformDispatcherError?.call(error, stack);

    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> initializeNotifications() async {
  final n = GetIt.instance.get<NotificationService>();
  await n.initialize();

  final permissionResponse = await n.hasPermissionToSendNotifications();
  if (permissionResponse == PermissionResponse.allowed) {
    await n.setUpReminderNotifications();
  }

  // TODO: since setUpReminderNotifications is idempotent, remove all scheduled notifications as part of init. EXCEPT ANY SHOWING CURRENTLY
}

void registerFirebaseAuthListener(
  PokeFirebase firebase,
  NavigatorState nav,
) {
  firebase.auth().userChanges().listen((User? user) async {
    if (user == null) {
      PokeLogger.instance().info('User is signed out');
      PokeLogger.removeStaticData('firebase_user');

      await nav.pushReplacement(MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ));
    } else {
      PokeLogger.addStaticData('firebase_user', {
        'uid': user.uid,
      });
      PokeLogger.instance().info('User is signed in!');

      // fetch all actions and calculate their due dates
      // and start keeping this list up-to-date in memory
      // TODO: what if this fails? Need a retry
      final reminderService = GetIt.instance.get<ReminderService>();
      await reminderService.init();

      await initializeNotifications();

      await nav.pushReplacement(MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ));
    }
  });
}
