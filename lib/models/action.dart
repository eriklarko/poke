// An action in this app is something the user wants to be poked about in the
// future, like watering a plant or replacing an AC filter.

import 'package:flutter/material.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/event_storage/serializable_event_data.dart';
import 'package:poke/models/watering_plants/water_plant.dart';

typedef ActionFromJson = Action Function(Map<String, dynamic>);
typedef EventDataFromJson = SerializableEventData Function(
    Map<String, dynamic>);

abstract class Action<EventDataType extends SerializableEventData?> {
  static final Map<String, (Type, ActionFromJson, EventDataFromJson?)>
      _factories = {};

  static void registerSubclasses() {
    registerSubclass(
      serializationKey: WaterPlantAction.serializationKey,
      type: WaterPlantAction,
      actionFromJson: WaterPlantAction.fromJson,
      eventDataFromJson: WaterEventData.fromJson,
    );
  }

  static void registerSubclass({
    required String serializationKey,
    required Type type,
    required ActionFromJson actionFromJson,
    EventDataFromJson? eventDataFromJson,
  }) {
    _factories[serializationKey] = (
      type,
      actionFromJson,
      eventDataFromJson,
    );
  }

  // In order for dart to know how to deserialize the JSON representation of an
  // action it needs to know which subtype of this class it is. This getter
  // gives dart that information.
  //
  // It might be tempting to return  `this.runtimeType.toString()` for that,
  // BUT! this string is part of the public API and changing it will make any
  // persisted actions unable to be deserialized. If the runtime type is
  // returned from this method, we'd be tying the class name to the public API
  // and renaming any action class would be a dangerous operation. That's bad.
  // Public APIs are important.
  //
  // This field cannot be final because json_serializable won't include it if it
  // is, which is stoooopid. Never change it ploxx.
  // ignore: prefer_final_fields
  /* NOTE! final */ String _serializationKey;

  Action({required String serializationKey})
      : _serializationKey = serializationKey;

  String get equalityKey;

  // Creates the UI used to show this action in the reminder list
  Widget buildReminderListItem(
      BuildContext context, (DateTime, EventDataType)? lastEvent);

  // Creates the UI to use when executing this action, or adding an event of
  // this action. An event in Poke is when an action was performed.
  Widget buildLogActionWidget(
    BuildContext context,
    (DateTime, EventDataType)? lastEvent,
    EventStorage eventStorage,
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> m = {
      'serializationKey': _serializationKey,
    };
    m.addAll(subclassToJson());
    return m;
  }

  Map<String, dynamic> subclassToJson();

  // Gosh, serialization in Dart is verbooose
  static Action fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('serializationKey')) {
      throw ArgumentError.value(
        json,
        'json',
        'Missing serialization key',
      );
    }

    final String serializationKey = json['serializationKey'];
    final jsonFactories = _factories[serializationKey];
    if (jsonFactories == null) {
      throw "No json factories registered for serialization key '$serializationKey'. Make sure to register custom actions with Action.registerSubclass(...)";
    }
    final (_, actionFromJson, _) = jsonFactories;
    return actionFromJson(json);
  }

  static SerializableEventData? eventDataFromJson({
    required Type actionType,
    required Map<String, dynamic>? json,
  }) {
    SerializableEventData? eventData;
    final dataFromJson = _getJsonFactoriesForType(actionType);
    if (dataFromJson != null) {
      if (json == null) {
        throw "expected event data but got null";
      }

      eventData = dataFromJson(json);
    }

    return eventData;
  }

  static EventDataFromJson? _getJsonFactoriesForType(Type t) {
    for (final v in _factories.values) {
      if (v.$1 == t) {
        return v.$3;
      }
    }

    return null;
  }

  Type eventDataType() {
    return EventDataType;
  }
}
