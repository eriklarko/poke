import 'package:flutter/material.dart' hide Action;
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/event.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/utils/date_formatter.dart';

class WateredPlant extends Event {
  final bool addedFertilizer;

  WateredPlant({required super.when, required this.addedFertilizer});
}

class WaterPlantAction extends Action<WateredPlant> {
  final Plant plant;

  WaterPlantAction({required this.plant, WateredPlant? lastEvent})
      : super(lastEvent: lastEvent);

  @override
  Widget buildReminderListItem(BuildContext context) {
    return Row(
      children: [
        plant.image,
        Column(
          children: [
            Text(plant.name),
            if (lastEvent != null)
              Column(
                children: [
                  Text('Last watered on ${formatDate(lastEvent!.when)}'),
                  if (lastEvent!.addedFertilizer)
                    const Text('included fertilizer'),
                ],
              ),
          ],
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }

  @override
  buildAddEventWidget(BuildContext context) {
    final fertilizerCheckbox = PokeCheckbox();
    return Column(
      children: [
        plant.image,
        Text(plant.name),
        if (lastEvent != null)
          Text('Last watered on ${formatDate(lastEvent!.when)}'),
        Row(
          children: [
            Text('Added fertilizer'),
            fertilizerCheckbox,
          ],
        ),
        PokeButton(
          onPressed: () {
            final event = WateredPlant(
                when: DateTime.now(),
                addedFertilizer: fertilizerCheckbox.isChecked);
            print('pressed btnn ${fertilizerCheckbox.isChecked}');
          },
          child: Text('Watered!'),
        ),
      ],
    );
  }
}
