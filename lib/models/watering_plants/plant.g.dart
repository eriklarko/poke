// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plant _$PlantFromJson(Map<String, dynamic> json) => Plant(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUri: json['imageUri'] == null
          ? null
          : Uri.parse(json['imageUri'] as String),
    );

Map<String, dynamic> _$PlantToJson(Plant instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageUri': instance.imageUri?.toString(),
    };
