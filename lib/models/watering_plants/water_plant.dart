import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/design_system/poke_time_ago.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/watering_plants/editable_plant_image.dart';
import 'package:poke/models/watering_plants/plant_image.dart';
import 'package:poke/notifications/notification_data.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/logger/poke_logger.dart';
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
  String get equalityKey => "water-${plant.id}";

  @override
  NotificationData getNotificationData() {
    // TODO: get the reminder here from GetIt so that the body can say "watering due 2 days ago"
    return NotificationData(
      title: "Time to water ${plant.name}",
      body: "You gots to show ${plant.name} some luv",
      bigPictureUrl: plant.imageUri?.toString(),
      actionButtons: [
        NotificationActionButton(key: equalityKey, label: "watered"),
      ],
    );
  }

  @override
  Widget buildReminderListItem(BuildContext context, Reminder reminder) {
    final lastEvent = getLastEvent();
    return Row(
      children: [
        PlantImage.fill(plant.image),
        PokeConstants.FixedSpacer(2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokeText(plant.name),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lastEvent != null)
                    PokeTimeAgo(
                      key: ValueKey('last-watered-${plant.id}'),
                      date: lastEvent.$1,
                      format: (timeAgo) => "Last watered $timeAgo",
                    ),
                  if (lastEvent?.$2!.addedFertilizer == true)
                    const PokeFinePrint('included fertilizer'),
                  if (reminder.dueDate != null)
                    PokeTimeAgo(
                      key: ValueKey('due-${plant.id}'),
                      date: reminder.dueDate!,
                      format: (timeAgo) => reminder.isDue()
                          ? "Due $timeAgo"
                          : "Will poke $timeAgo",
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  buildLogActionWidget(
    BuildContext context,
    Persistence persistence, {
    Function()? onActionLogged,
  }) {
    final lastEvent = getLastEvent();
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
            text: 'Watered!',
            onPressed: () {
              _logActionController.setLoading();

              PokeLogger.instance().debug(
                'Pressed water plant button',
                data: {'fertCheckboxChecked': fertilizerCheckbox.isChecked},
              );

              persistence
                  .logAction(
                this,
                clock.now(),
                eventData: WaterEventData(
                  addedFertilizer: fertilizerCheckbox.isChecked,
                ),
              )
                  .then((_) {
                _logActionController.setSuccessful();
                onActionLogged?.call();
              }).catchError((err) {
                _logActionController.setErrored(err);
              });
            },
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
  Widget buildDetailsScreen(BuildContext context) {
    return Column(
      children: [
        PokeText("${plant.name} details"),
        PlantImage.large(plant.image),
      ],
    );
  }

  factory WaterPlantAction.fromJson(Map<String, dynamic> json) {
    return _$WaterPlantActionFromJson(json);
  }

  @override
  WaterEventData parseEventData(Map<String, dynamic> json) {
    return WaterEventData.fromJson(json);
  }

  @override
  Map<String, dynamic> subclassToJson() {
    return _$WaterPlantActionToJson(this);
  }

  @override
  String toString() {
    return "water ${plant.name}";
  }

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
