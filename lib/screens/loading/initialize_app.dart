import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/test-action/test_action.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

import 'package:poke/event_storage/firebase_storage.dart';
import 'package:poke/logger/poke_logger.dart';

import 'package:poke/screens/auth/login_screen.dart';
import 'package:poke/screens/home_screen.dart';
import 'package:poke/screens/loading/firebase.dart';
import 'package:poke/utils/nav_service.dart';

Future initializeApp({
  PokeFirebase firebase = const PokeFirebase(),
  NavigatorState? nav,
}) async {
  await firebase.initializeApp();

  setupCrashHandlers(firebase);

  registerServices(firebase);

  registerFirebaseAuthListener(firebase, nav ?? NavService.instance);
}

void registerServices(PokeFirebase firebase) {
  final getIt = GetIt.instance;

  //getIt.registerSingleton<EventStorage>(InMemoryStorage());
  getIt.registerSingleton<EventStorage>(FirebaseStorage(firebase));
  getIt.registerSingleton<PokeLogger>(FirebaseLogger());
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

// these routes are put in variables so that tests can verify they're being
// navigated to
final MaterialPageRoute toLoginScreen = MaterialPageRoute(
  builder: (_) => const LoginScreen(),
);

final MaterialPageRoute toHomeScreen = MaterialPageRoute(
  builder: (_) => const HomeScreen(),
);

void registerFirebaseAuthListener(PokeFirebase firebase, NavigatorState nav) {
  firebase.auth().userChanges().listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
      nav.pushReplacement(toLoginScreen);
    } else {
      print('User is signed in!');
      /*_addTestEvents(GetIt.instance.get<EventStorage>())
          .then((_) => nav.pushReplacement(toHomeScreen))
          .onError((error, stackTrace) =>
              print('test event error: $error; $stackTrace'));
      */
      nav.pushReplacement(toHomeScreen);
    }
  });
}

Future _addTestEvents(EventStorage eventStorage) async {
  await eventStorage.logAction(
    WaterPlantAction(
      plant: Plant(id: 'frank', name: 'Frank'),
      addedFertilizer: false,
    ),
    DateTime.now(),
  );
  await eventStorage.logAction(
    TestAction(id: 'hello'),
    DateTime.now(),
  );
}
