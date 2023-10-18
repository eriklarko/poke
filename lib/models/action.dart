// An action in this app is something the user wants to be poked about in the
// future, like watering a plant or replacing an AC filter.

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/test-action/test_action.dart';

abstract class Action {
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime? lastEvent;

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
  /* NOTE! final */ String serializationKey;

  Action({required this.serializationKey, this.lastEvent});

  // Creates the UI used to show this action in the reminder list
  Widget buildReminderListItem(BuildContext context);

  // Creates the UI to use when executing this action, or adding an event of
  // this action. An event in Poke is when an action was performed.
  Widget buildLogActionWidget(BuildContext context, EventStorage eventStorage);

  Map<String, dynamic> toJson();

  // Gosh, serialization in Dart is verbooose
  static Action fromJson(Map<String, dynamic> json) {
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
}

class ReplaceACFilter extends Action {
  ReplaceACFilter() : super(serializationKey: 'replace-ac-filter');

  @override
  Widget buildReminderListItem(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  Widget buildLogActionWidget(BuildContext context, EventStorage eventStorage) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }
}
