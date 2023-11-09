import 'package:flutter/material.dart' hide Action;
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/design_system/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/event_storage/serializable_event_data.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/utils/date_formatter.dart';

part "water_plant.g.dart";

@JsonSerializable(explicitToJson: true)
class WaterPlantAction extends Action<WaterEventData> {
  final Plant plant;

  // create controller used to set loading/success states of the button that
  // logs the action in `buildLogActionWidget`
  final _logActionController = PokeAsyncWidgetController();

  static const String serializationKey = 'water-plant';

  WaterPlantAction({required this.plant})
      : super(serializationKey: serializationKey);

  @override
  Widget buildReminderListItem(
      BuildContext context, (DateTime, WaterEventData)? lastEvent) {
    return Row(
      children: [
        plant.image,
        Column(
          children: [
            PokeText(plant.name),
            if (lastEvent != null)
              Column(
                children: [
                  PokeFinePrint('Last watered on ${formatDate(lastEvent.$1)}'),
                  if (lastEvent.$2.addedFertilizer == true)
                    const PokeFinePrint('included fertilizer'),
                ],
              ),
          ],
        ),
      ],
    );
  }

  @override
  buildLogActionWidget(
    BuildContext context,
    (DateTime, WaterEventData)? lastEvent,
    EventStorage eventStorage,
  ) {
    final fertilizerCheckbox = PokeCheckbox();

    return Column(
      children: [
        plant.image,
        PokeText(plant.name),
        if (lastEvent != null)
          PokeText('Last watered on ${formatDate(lastEvent.$1)}'),
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
              eventStorage
                  .logAction(
                this,
                DateTime.now(),
                eventData: WaterEventData(
                    addedFertilizer: fertilizerCheckbox.isChecked),
              )
                  .then((_) {
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
    return "water ${plant.name}";
  }

  @override
  Map<String, dynamic> subclassToJson() {
    return _$WaterPlantActionToJson(this);
  }

  factory WaterPlantAction.fromJson(Map<String, dynamic> json) {
    return _$WaterPlantActionFromJson(json);
  }

  @override
  String get equalityKey => "water-${plant.id}";

  @override
  bool operator ==(Object other) {
    if (other is! WaterPlantAction) {
      return false;
    }

    return plant == other.plant;
  }

  @override
  int get hashCode => plant.hashCode;
}

@JsonSerializable()
class WaterEventData extends SerializableEventData {
  final bool addedFertilizer;

  WaterEventData({required this.addedFertilizer});

  @override
  Map<String, dynamic> toJson() {
    return _$WaterEventDataToJson(this);
  }

  factory WaterEventData.fromJson(Map<String, dynamic> json) {
    return _$WaterEventDataFromJson(json);
  }
}
