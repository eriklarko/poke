// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestActionWithData _$TestActionWithDataFromJson(Map<String, dynamic> json) =>
    TestActionWithData(
      id: json['id'] as String?,
    );

Map<String, dynamic> _$TestActionWithDataToJson(TestActionWithData instance) =>
    <String, dynamic>{
      'events': Action.eventsToJson(instance.events),
      'id': instance.id,
    };

Data _$DataFromJson(Map<String, dynamic> json) => Data(
      json['someProp'] as String,
    );

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
      'someProp': instance.someProp,
    };
