// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_plant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaterPlantAction _$WaterPlantActionFromJson(Map<String, dynamic> json) =>
    WaterPlantAction(
      plant: Plant.fromJson(Map<String, dynamic>.from(json['plant'])),
      addedFertilizer: json['addedFertilizer'] as bool,
    )..serializationKey = json['serializationKey'] as String;

Map<String, dynamic> _$WaterPlantActionToJson(WaterPlantAction instance) =>
    <String, dynamic>{
      'serializationKey': instance.serializationKey,
      'plant': instance.plant.toJson(),
      'addedFertilizer': instance.addedFertilizer,
    };
