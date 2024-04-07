import 'package:flutter_test/flutter_test.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

void main() {
  test('serializes as expected', () {
    final Plant plant = Plant(
      id: '1',
      name: 'plant-1',
      imageUri: Uri.parse('https://placekitten.com/200/200'),
    );
    final WaterPlantAction sut = WaterPlantAction(plant: plant);

    expect(
      sut.toJson(),
      equals({
        'serializationKey': 'water-plant',
        'plant': {
          'id': '1',
          'name': 'plant-1',
          'imageUri': 'https://placekitten.com/200/200',
        },
        'events': {},
      }),
    );
  });

  test('deserializes as expected', () {
    final Map<String, dynamic> json = {
      'serializationKey': 'water-plant',
      'plant': {
        'id': '1',
        'name': 'plant-1',
        'imageUri': 'https://placekitten.com/200/200',
      },
    };

    expect(
      WaterPlantAction.fromJson(json),
      equals(
        WaterPlantAction(
          plant: Plant(
            id: '1',
            name: 'plant-1',
            imageUri: Uri.parse('https://placekitten.com/200/200'),
          ),
        ),
      ),
    );
  });
}
