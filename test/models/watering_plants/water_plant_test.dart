import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/design_system/poke_time_ago.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

import '../../screens/loading/initialize_app_test.dart';
import '../../test_app.dart';

final arbitraryPlant = Plant(
  id: '1337',
  name: 'some random plant',
);

void main() {
  group("reminder list item", () {
    testWidgets('shows plant name', (tester) async {
      final WaterPlantAction sut = WaterPlantAction(
        plant: Plant(
          id: '15',
          name: 'Gatwa',
        ),
      );

      // TODO: mock build context
      await pumpInTestApp(
        tester,
        sut.buildReminderListItem(
          MockBuildContext(),
          Reminder(action: sut, dueDate: DateTime.now()),
        ),
      );

      expect(find.text(sut.plant.name), findsOneWidget);
    });

    testWidgets('shows last watered', (tester) async {
      final WaterPlantAction sut = WaterPlantAction(
        plant: arbitraryPlant,
      );

      // add an event with a known date
      final eventDate = DateTime.parse('1963-11-23');
      sut.withEvent(
        eventDate,
        eventData: WaterEventData(addedFertilizer: false),
      );

      final tenDaysFromEvent = Clock.fixed(
        eventDate.add(const Duration(days: 10)),
      );
      await withClock(tenDaysFromEvent, () async {
        // TODO: mock build context
        await pumpInTestApp(
          tester,
          sut.buildReminderListItem(
            MockBuildContext(),
            Reminder(action: sut, dueDate: DateTime.now()),
          ),
        );

        final textFinder = find.descendant(
          of: find.byKey(ValueKey("last-watered-${arbitraryPlant.id}")),
          matching: find.byType(PokeText),
        );
        final Text text = tester.firstWidget(textFinder);
        expect(text.data, contains("10 days ago"));
      });
    });

    testWidgets("shows when to water next", (tester) async {
      final WaterPlantAction sut = WaterPlantAction(
        plant: arbitraryPlant,
      );

      final dueDate = DateTime.parse('1963-11-23');

      final tenDaysBeforeDue = Clock.fixed(
        dueDate.subtract(const Duration(days: 10)),
      );
      await withClock(tenDaysBeforeDue, () async {
        // TODO: mock build context
        await pumpInTestApp(
          tester,
          sut.buildReminderListItem(
            MockBuildContext(),
            Reminder(action: sut, dueDate: dueDate),
          ),
        );

        final textFinder = find.descendant(
          of: find.byKey(ValueKey("due-${arbitraryPlant.id}")),
          matching: find.byType(PokeText),
        );
        final Text text = tester.firstWidget(textFinder);

        expect(text.data, contains("10 days from now"));
      });
    });
  });

  group("log action widget", () {
    testWidgets("...", (tester) async {
      // TODO: write tests
    });
  });

  group("serialization", () {
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
  });
}
