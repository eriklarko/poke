import 'package:clock/clock.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/watering_plants/editable_plant_image.dart';
import 'package:poke/models/watering_plants/plant_image.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/watering_plants/new_instance_widget.dart';
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
        PlantImage.fill(image: plant.image),
        PokeConstants.FixedSpacer(),
        Expanded(
          child: Column(
            children: [
              PokeText(
                plant.name,
                center: true,
              ),
              Column(
                children: [
                  PokeFinePrint(_buildLastWateredString(lastEvent?.$1)),
                  PokeFinePrint(
                    lastEvent?.$2.addedFertilizer == true
                        ? 'included fertilizer'
                        : '',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildLastWateredString(DateTime? lastEvent) {
    if (lastEvent == null) {
      return '';
    }

    int daysSince = clock.now().difference(lastEvent).inDays;
    String dayS = daysSince == 1 ? "day" : "days";

    return 'Last watered $daysSince $dayS ago';
  }

  @override
  buildLogActionWidget(
    BuildContext context,
    (DateTime, WaterEventData)? lastEvent,
    Persistence persistence,
  ) {
    final fertilizerCheckbox = PokeCheckbox();

    return Column(
      children: [
        EditablePlantImage(action: this),
        PokeText(plant.name),
        if (lastEvent != null)
          PokeText('Last watered on ${formatDate(lastEvent.$1)}'),
        Row(
          children: [
            PokeText('Added fertilizer'),
            fertilizerCheckbox,
          ],
        ),
        PokeConstants.FixedSpacer(2),
        PokeAsyncWidget.simple(
          controller: _logActionController,
          idle: PokeButton.primary(
            onPressed: () {
              _logActionController.setLoading();

              PokeLogger.instance().debug(
                'Pressed water plant button',
                data: {'fertCheckboxChecked': fertilizerCheckbox.isChecked},
              );

              // TODO: replace DateTime.now() with something testable
              persistence
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

  static Widget buildNewInstanceWidget(
    BuildContext context,
    Persistence persistence,
  ) {
    return NewInstanceWidget(
      persistence: persistence,
    );
  }

  @override
  Widget buildDetailsScreen(
    BuildContext context,
    Map<DateTime, SerializableEventData?> events,
  ) {
    return Column(
      children: [
        PokeText("${plant.name} details"),
        plant.image,
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
