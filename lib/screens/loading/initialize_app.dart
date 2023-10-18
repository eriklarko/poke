import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

import 'package:poke/event_storage/in_memory_storage.dart';
import 'package:poke/logger/poke_logger.dart';

import 'package:poke/screens/auth/login_screen.dart';
import 'package:poke/screens/home_screen.dart';
import 'package:poke/screens/loading/firebase.dart';
import 'package:poke/utils/nav_service.dart';

Future initializeApp({PokeFirebase firebase = const PokeFirebase()}) async {
  await firebase.initializeApp();

  setupCrashHandlers(firebase);

  registerServices();

  await _addTestEvents(GetIt.instance.get<EventStorage>());

  registerFirebaseAuthListener(firebase);
}

void registerServices() {
  final getIt = GetIt.instance;

  getIt.registerSingleton<EventStorage>(InMemoryStorage());
  getIt.registerSingleton<PokeLogger>(FirebaseLogger());
}

void setupCrashHandlers(PokeFirebase firebase) {
  FlutterError.onError = (errorDetails) {
    FlutterError.presentError(errorDetails);
    firebase.crashlytics().recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.presentError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    firebase.crashlytics().recordError(error, stack, fatal: true);
    return true;
  };
}

void registerFirebaseAuthListener(PokeFirebase firebase) {
  firebase.auth().userChanges().listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
      NavService.instance.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      print('User is signed in!');
      NavService.instance.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  });
}

Future _addTestEvents(EventStorage eventStorage) async {
  await eventStorage.logAction(
    WaterPlantAction(
      plant: Plant(name: 'Frank'),
      addedFertilizer: false,
    ),
    DateTime.now(),
  );
}
