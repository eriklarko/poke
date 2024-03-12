import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' hide Persistence;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/logger/firebase_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

import 'package:poke/persistence/firebase_firestore_persistence.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/predictor/predictor.dart';
import 'package:poke/predictor/time_of_day_aware_average_predictor.dart';

import 'package:poke/screens/auth/login_screen.dart';
import 'package:poke/screens/home_screen.dart';
import 'package:poke/screens/loading/poke_firebase.dart';
import 'package:poke/utils/nav_service.dart';

Future initializeApp({
  PokeFirebase firebase = const PokeFirebase(),
  NavigatorState? nav,
}) async {
  await firebase.initializeApp();

  setupCrashHandlers(firebase);

  Action.registerSubclasses();

  await registerAppCheck(firebase);

  registerServices(firebase);

  registerFirebaseAuthListener(firebase, nav ?? NavService.instance);
}

registerAppCheck(PokeFirebase firebase) async {
  await firebase.appCheck().activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );
}

void registerServices(PokeFirebase firebase) {
  final getIt = GetIt.instance;

  try {
    // because of hot-reloading we need to allow reassignments in debug
    // restore this behavior in `finally`
    if (kDebugMode) {
      getIt.allowReassignment = true;
    }

    //getIt.registerSingleton<Persistence>(InMemoryPersistence());
    getIt
        .registerSingleton<Persistence>(FirebaseFirestorePersistence(firebase));
    getIt.registerSingleton<PokeLogger>(FirebaseLogger(firebase));
    getIt.registerSingleton<Predictor>(TimeOfDayAwareAveragePredictor());
  } finally {
    getIt.allowReassignment = false;
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

void registerFirebaseAuthListener(PokeFirebase firebase, NavigatorState nav) {
  firebase.auth().userChanges().listen((User? user) async {
    if (user == null) {
      PokeLogger.instance().info('User is signed out');
      await nav.pushReplacement(MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ));
    } else {
      PokeLogger.instance().info('User is signed in!');
      /*_addTestEvents(GetIt.instance.get<Persistence>())
          .then((_) => nav.pushReplacement(MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              )))
          .onError((error, stackTrace) =>
              print('test event error: $error; $stackTrace'));
      */
      await nav.pushReplacement(MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ));
    }
  });
}

Future _addTestEvents(Persistence persistence) async {
  await persistence.logAction(
    WaterPlantAction(
      plant: Plant(id: 'frank', name: 'Frank'),
    ),
    DateTime.now(),
    eventData: WaterEventData(addedFertilizer: false),
  );
}
