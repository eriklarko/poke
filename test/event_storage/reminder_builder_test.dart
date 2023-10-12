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

    final e1 = WateredPlant(
      when: clock.next(),
      plant: plant1,
      addedFertilizer: false,
    );
    final e2 = WateredPlant(
      when: clock.next(),
      plant: plant2,
      addedFertilizer: false,
    );
    final e3 = WateredPlant(
      when: clock.next(),
      plant: plant1,
      addedFertilizer: false,
    );

    await eventStorage.addEvent(e1);
    await eventStorage.addEvent(e2);
    await eventStorage.addEvent(e3);

    final expected = {
      plant1: [e1, e3],
      plant2: [e2],
    };

    expect(grouper([e1, e2, e3]), equals(expected));
  });
}
