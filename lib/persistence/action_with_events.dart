import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/models/action.dart';

class ActionWithEvents<TEventData extends SerializableEventData?,
    TAction extends Action<TEventData>> {
  final TAction action;
  final Map<DateTime, TEventData?> events = {};

  ActionWithEvents(this.action);

  ActionWithEvents.single(this.action, DateTime when, {TEventData? data}) {
    add(when, eventData: data);
  }

  ActionWithEvents.multiple(this.action, Map<DateTime, TEventData> data) {
    data.forEach((key, value) {
      add(key, eventData: value);
    });
  }

  ActionWithEvents<TEventData, TAction> add(DateTime when,
      {TEventData? eventData}) {
    events[when] = eventData;
    return this;
  }

  (DateTime, TEventData?)? getLastEvent() {
    final eventTimestamps = List.of(events.keys);
    eventTimestamps.sort((a, b) => b.compareTo(a));

    if (events.isEmpty) {
      return null;
    }

    final lastEventData = events[eventTimestamps.first];
    if (action.eventDataType() == Void) {
      if (lastEventData != null) {
        throw "invalid event data type. Got ${lastEventData.runtimeType} expected ${action.eventDataType()}";
      }
    } else if (lastEventData.runtimeType != action.eventDataType()) {
      // This should probably not throw, but it needs to be indicated somehow...
      throw "invalid event data type. Got ${lastEventData.runtimeType} expected ${action.eventDataType()}";
    }

    return (eventTimestamps.first, lastEventData);
  }

  @override
  bool operator ==(Object other) {
    if (other is! ActionWithEvents) {
      return false;
    }

    return action == other.action && mapEquals(events, other.events);
  }

  @override
  int get hashCode => action.hashCode + events.hashCode;

  @override
  String toString() {
    return '$action - $events';
  }
}
