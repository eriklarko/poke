import 'package:flutter/material.dart' hide Action;
import 'package:poke/design_system/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/event.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/utils/date_formatter.dart';

class WateredPlant extends Event {
  final Plant plant;
  final bool addedFertilizer;

  WateredPlant({
    required super.when,
    required this.plant,
    required this.addedFertilizer,
  });
}

class WaterPlantAction extends Action<WateredPlant> {
  final Plant plant;
  final _addEventController = PokeAsyncWidgetController();

  WaterPlantAction({required this.plant, WateredPlant? lastEvent})
      : super(lastEvent: lastEvent);

  @override
  Widget buildReminderListItem(BuildContext context) {
    return Row(
      children: [
        plant.image,
        Column(
          children: [
            PokeText(plant.name),
            if (lastEvent != null)
              Column(
                children: [
                  PokeFinePrint(
                      'Last watered on ${formatDate(lastEvent!.when)}'),
                  if (lastEvent!.addedFertilizer)
                    const PokeFinePrint('included fertilizer'),
                ],
              ),
          ],
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }

  @override
  buildAddEventWidget(BuildContext context, EventStorage eventStorage) {
    final fertilizerCheckbox = PokeCheckbox();

    return Column(
      children: [
        plant.image,
        PokeText(plant.name),
        if (lastEvent != null)
          PokeText('Last watered on ${formatDate(lastEvent!.when)}'),
        Row(
          children: [
            const PokeText('Added fertilizer'),
            fertilizerCheckbox,
          ],
        ),
        PokeAsyncWidget(
          controller: _addEventController,
          idle: PokeButton(
            onPressed: () {
              _addEventController.setLoading();

              final event = WateredPlant(
                when: DateTime.now(),
                plant: plant,
                addedFertilizer: fertilizerCheckbox.isChecked,
              );
              print('pressed btnn ${fertilizerCheckbox.isChecked}');

              eventStorage.addEvent(event).then((_) {
                _addEventController.setSuccessful();
              }).catchError((err) {
                _addEventController.setErrored(err);
              });
            },
            text: 'Watered!',
          ),
          success: const Text('done!'),
          loading: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(),
          ),
          error: (error) {
            return Text(error.toString());
          },
        ),
      ],
    );
  }
}
