import 'package:json_annotation/json_annotation.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/test-action/test_action.dart';
import 'package:poke/utils/date_formatter.dart';

part 'event.g.dart';

// An event is when an action was performed, like watering a plant or changing
// AC filter.
//
// This class can be serialized to JSON as per
// https://docs.flutter.dev/data-and-backend/serialization/json?gclid=EAIaIQobChMI1_GllqDzgQMVCkxyCh0p9gSYEAAYASAAEgJUSvD_BwE&gclsrc=aw.ds#setting-up-json_serializable-in-a-project
// When making changes to this class, run `./scripts/generate_json_files.sh` in
// the git root to update the generated files.
@JsonSerializable()
class Event {
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final Action action;
  final DateTime when;

  Event({required this.action, required this.when});

  @override
  String toString() {
    return "$action at ${formatDate(when)}";
  }

  //////////////////////////////////////////////////////////
  /////////////////// OVERRIDE EQUALITY ////////////////////
  @override
  bool operator ==(Object other) {
    final isEvent = other is Event;
    final correctType = other.runtimeType == runtimeType;

    if (!isEvent || !correctType) {
      return false;
    }

    final actionEq = other.action == action;
    final whenEq = other.when == when;

    return actionEq && whenEq;

    /*return other is Event &&
        other.runtimeType == runtimeType &&
        other.action == action &&
        other.when == other.when;
        */
  }

  @override
  int get hashCode => action.hashCode + when.hashCode;
  /////////////////// OVERRIDE EQUALITY ////////////////////
  //////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////
  ////////////////// JSON SERIALIZATION ////////////////////
  Map<String, dynamic> toJson() => _$EventToJson(this);

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  static Action _fromJson(Map<String, dynamic> json) {
    if (json.containsKey('serializationKey')) {
      switch (json['serializationKey']) {
        // this json stuff is so wonderful
        case 'test-action':
          return TestAction.fromJson(json);
      }

      print('fromJson $json ${json.runtimeType}');
      throw ArgumentError.value(
        json,
        'json',
        'Unknown serialization key "$json.serializationKey". Please add it to the switch statement in the Event class',
      );
    }

    throw ArgumentError.value(
      json,
      'json',
      'Event._fromJson cannot handle this JSON payload. Please add a handler to _fromJson.',
    );
  }

  static Object _toJson<ActionType extends Action>(ActionType object) {
    return object.toJson();
  }
  ////////////////// JSON SERIALIZATION ////////////////////
  //////////////////////////////////////////////////////////
}
