// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_plant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaterPlantAction _$WaterPlantActionFromJson(Map<String, dynamic> json) =>
    WaterPlantAction(
      plant: Plant.fromJson(json['plant'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WaterPlantActionToJson(WaterPlantAction instance) =>
    <String, dynamic>{
      'events': Action.eventsToJson(instance.events),
      'plant': instance.plant.toJson(),
    };

WaterEventData _$WaterEventDataFromJson(Map<String, dynamic> json) =>
    WaterEventData(
      addedFertilizer: json['addedFertilizer'] as bool,
    );

Map<String, dynamic> _$WaterEventDataToJson(WaterEventData instance) =>
    <String, dynamic>{
      'addedFertilizer': instance.addedFertilizer,
    };
