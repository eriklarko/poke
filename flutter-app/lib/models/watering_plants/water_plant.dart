import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_swipeable.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/watering_plants/widgets/action_screen/action_screen.dart';
import 'package:poke/models/watering_plants/widgets/reminder_list_item.dart';
import 'package:poke/notifications/notification_data.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/models/watering_plants/widgets/new_instance_widget.dart';
import 'package:poke/models/watering_plants/plant.dart';

part "water_plant.g.dart";

@JsonSerializable(explicitToJson: true)
class WaterPlantAction extends Action<WaterEventData> {
  final Plant plant;
  final Persistence persistence = GetIt.instance.get<Persistence>();

  static const String serializationKey = 'water-plant';

  WaterPlantAction({required this.plant})
      : super(serializationKey: serializationKey);

  @override
  String get equalityKey => "water-${plant.id}";

  @override
  String getHumanReadableName() {
    return plant.name;
  }

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
    return PlantReminderListItem(reminder: reminder);
  }

  // TODO: test
  @override
  List<SwipeAction<Reminder>> get reminderListSwipeActions => [
        SwipeAction.async(
          act: (reminder) {
            return persistence.logAction(
              reminder.action,
              clock.now(),
              eventData: WaterEventData(addedFertilizer: false),
            );
          },
          widget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop_outlined),
              const Text("watered"),
            ],
          ),
          wrapAsyncWidget: (w) => Container(
            decoration: BoxDecoration(
              color: PokeConstants.colors.primary,
            ),
            child: w,
          ),
        ),
      ];

  static Widget buildNewInstanceWidget(
    BuildContext context,
    Persistence persistence,
  ) {
    return NewInstanceWidget();
  }

  @override
  Widget buildDetailsScreen(BuildContext context) {
    return ActionScreen(action: this);
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
