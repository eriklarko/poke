import 'package:flutter_test/flutter_test.dart';
import 'package:poke/event_storage/in_memory_storage.dart';
import 'package:poke/event_storage/reminder_builder.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

import '../utils/clock.dart';

final plant1 = Plant(name: 'Plant 1');
final plant2 = Plant(name: 'Plant 2');

final clock = Clock();

void main() {
  test('Groups plant events based on which plant was watered', () async {
    final eventStorage = InMemoryStorage();

    // create two different actions to be logged at different timestamps further
    // down
    final a1 = WaterPlantAction(
      plant: plant1,
      addedFertilizer: false,
    );
    final a2 = WaterPlantAction(
      plant: plant2,
      addedFertilizer: false,
    );

    // get references to the timestamps we're logging the actions at so that we
    // can check them later
    final ts1 = clock.next();
    final ts2 = clock.next();
    final ts3 = clock.next();

    // log the actions at their corresponding timestamps
    await eventStorage.logAction(a1, ts1);
    await eventStorage.logAction(a2, ts2);
    await eventStorage.logAction(a1, ts3);

    final expected = {
      a1: [ts1, ts3],
      a2: [ts2],
    };
    expect(
      await eventStorage.getAll(),
      equals(expected),
    );
  });
}
