import 'package:get_it/get_it.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:poke/firebase_options.dart';

Future initializeApp() {
  return Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    _addTestEvents(GetIt.instance.get<EventStorage>()),
  ]);
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
