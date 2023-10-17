import 'package:flutter/material.dart' hide Action;
import 'package:poke/design_system/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/utils/date_formatter.dart';

class WaterPlantAction extends Action {
  final Plant plant;
  final bool addedFertilizer;

  // create controller used to set loading/success states of the button that
  // logs the action in `buildLogActionWidget`
  final _logActionController = PokeAsyncWidgetController();

  WaterPlantAction({
    required this.plant,
    required this.addedFertilizer,
    super.lastEvent,
  }) : super(serializationKey: 'water-plant');

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
                  PokeFinePrint('Last watered on ${formatDate(lastEvent!)}'),
                  if (addedFertilizer)
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
  buildLogActionWidget(BuildContext context, EventStorage eventStorage) {
    final fertilizerCheckbox = PokeCheckbox();

    return Column(
      children: [
        plant.image,
        PokeText(plant.name),
        if (lastEvent != null)
          PokeText('Last watered on ${formatDate(lastEvent!)}'),
        Row(
          children: [
            const PokeText('Added fertilizer'),
            fertilizerCheckbox,
          ],
        ),
        PokeAsyncWidget(
          controller: _logActionController,
          idle: PokeButton.primary(
            onPressed: () {
              _logActionController.setLoading();

              print('pressed btnn ${fertilizerCheckbox.isChecked}');

              // TODO: replace DateTime.now() with something testable
              eventStorage.logAction(this, DateTime.now()).then((_) {
                _logActionController.setSuccessful();
              }).catchError((err) {
                _logActionController.setErrored(err);
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

  @override
  String toString() {
    return "water ${plant.name} ${addedFertilizer ? "with fertilizer" : "without fertilizer"}";
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
