// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
      action: Event._fromJson(json['action'] as Map<String, dynamic>),
      when: DateTime.parse(json['when'] as String),
    );

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
      'action': Event._toJson(instance.action),
      'when': instance.when.toIso8601String(),
    };
