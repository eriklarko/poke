import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';

abstract class Action<EventDataType extends SerializableEventData?> {
  ////////////////////////////////////////////////////////////////
  /////////////////// SUBCLASS REGISTRATION //////////////////////
  static final Map<String, ActionSubclassData> _subclasses = {};

  static void registerSubclasses() {
    registerSubclass(
      serializationKey: WaterPlantAction.serializationKey,
      actionFromJson: WaterPlantAction.fromJson,
      newInstanceBuilder: WaterPlantAction.buildNewInstanceWidget,
    );
  }

  static void registerSubclass({
    required String serializationKey,
    required ActionFromJson actionFromJson,
    required NewInstanceBuilder newInstanceBuilder,
  }) {
    _subclasses[serializationKey] = ActionSubclassData(
      serializationKey: serializationKey,
      actionFromJson: actionFromJson,
      newInstanceBuilder: newInstanceBuilder,
    );
  }

  static UnmodifiableListView<ActionSubclassData> registeredActions() {
    return UnmodifiableListView(_subclasses.values);
  }
  /////////////////// SUBCLASS REGISTRATION //////////////////////
  ////////////////////////////////////////////////////////////////

  @JsonKey(includeFromJson: true, includeToJson: true, toJson: eventsToJson)
  final Map<DateTime, EventDataType?> events = {};

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
  // ignore: unused_field
  final String _serializationKey;

  Action({required String serializationKey})
      : _serializationKey = serializationKey;

  // Used by firebase storage to generate a string representation of the action.
  // Kind of like a hash but meant to be human readable.
  // NOTE: Should follow the same rules as `hashCode`
  String get equalityKey;

  Action withEvents(Map<DateTime, EventDataType?> events) {
    this.events.addAll(events);
    return this;
  }

  Action withEvent(DateTime when, {EventDataType? eventData}) {
    this.events[when] = eventData;
    return this;
  }

  (DateTime, EventDataType?)? getLastEvent() {
    // Improvement: cache response; clear when `events` is modified
    if (events.isEmpty) {
      return null;
    }

    final eventTimestamps = List.of(events.keys);
    eventTimestamps.sort((a, b) => b.compareTo(a));

    if (EventDataType == Null) {
      return (eventTimestamps.first, null);
    }

    final lastEventData = events[eventTimestamps.first];
    if (lastEventData == null) {
      throw "tried reading event data for timestmap ${eventTimestamps.first} but found none";
    }
    return (eventTimestamps.first, lastEventData);
  }

  void removeEvent(DateTime eventTime) {
    events.remove(eventTime);
  }

  //////////////////////////////////////////////////////////////
  /////////////////// WIDGET BUILDERS //////////////////////////

  // Creates the UI used to show this action in the reminder list
  Widget buildReminderListItem(BuildContext context, Reminder reminder);

  // Creates the UI to use when executing this action, or adding an event of
  // this action. An event in Poke is when an action was performed.
  Widget buildLogActionWidget(
    BuildContext context,
    Persistence persistence, {
    Function()? onActionLogged,
  });

  Widget buildDetailsScreen(BuildContext context);
  /////////////////// WIDGET BUILDERS //////////////////////////
  //////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////
  /////////////////// JSON STUFF ///////////////////////////////

  String getSerializationKey() {
    return _serializationKey;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> eventsJson = {};
    this.events.forEach((key, value) {
      eventsJson[key.toIso8601String()] = value?.toJson();
    });

    final Map<String, dynamic> m = {
      'serializationKey': _serializationKey,
      'events': eventsJson,
    };
    m.addAll(subclassToJson());
    return m;
  }

  Map<String, dynamic> subclassToJson();

  static Action fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('serializationKey')) {
      throw ArgumentError.value(
        json,
        'json',
        'Missing serialization key',
      );
    }

    final String serializationKey = json['serializationKey'];
    final subclassData = _subclasses[serializationKey];
    if (subclassData == null) {
      throw "No action subclass registered for serialization key '$serializationKey'. Make sure to register custom actions with Action.registerSubclass(...)";
    }

    final a = subclassData.actionFromJson(json);
    final eventsJson = json['events'];
    if (eventsJson != null) {
      a._parseAndAddEvents(eventsJson);
    }
    return a;
  }

  // Doing parse AND add in non-static context so that the type of the event
  // data is kept. with `static SerializableEventData parseEvent(json)` the
  // concrete type is lost and only the generic knowledge
  // `SerializableEventData` is left. This puts `action.addEvents(...)` in an
  // odd place; it wants to be `void addEvents(Map<x, EventDataType)`, but you
  // can't pass SerializableEventData into EventDataType.
  //   final SerializableEventData a = ...
  //   final EventDataType b = a; // compile failure
  void _parseAndAddEvents(Map<String, dynamic> json) {
    final events = <DateTime, EventDataType?>{};
    for (final jsonEntry in json.entries) {
      final eventTimestamp = DateTime.parse(jsonEntry.key);

      final hasEventData = EventDataType != Null;
      final EventDataType? eventData =
          hasEventData ? parseEventData(jsonEntry.value) : null;

      events[eventTimestamp] = eventData;
    }

    this.events.addAll(events);
  }

  static Map<String, dynamic> eventsToJson(
    Map<DateTime, SerializableEventData?> events,
  ) {
    return events.map(
      (key, value) => MapEntry<String, dynamic>(
        key.toIso8601String(),
        value?.toJson(),
      ),
    );
  }

  EventDataType parseEventData(Map<String, dynamic> json);
  /////////////////// JSON STUFF ///////////////////////////////
  //////////////////////////////////////////////////////////////
}

typedef ActionFromJson = Action Function(Map<String, dynamic>);
typedef NewInstanceBuilder = Widget Function(BuildContext, Persistence);

class ActionSubclassData {
  final String serializationKey;
  final ActionFromJson actionFromJson;
  final NewInstanceBuilder newInstanceBuilder;

  ActionSubclassData({
    required this.serializationKey,
    required this.actionFromJson,
    required this.newInstanceBuilder,
  });
}
