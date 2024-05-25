import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/notifications/notification_data.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';

part 'test_action.g.dart';

void registerTestActions() {
  Action.registerSubclass(
    serializationKey: TestAction.serializationKey,
    actionFromJson: TestAction.fromJson,
    newInstanceBuilder: (_, __) => Container(),
  );

  Action.registerSubclass(
    serializationKey: TestActionWithData.serializationKey,
    actionFromJson: TestActionWithData.fromJson,
    newInstanceBuilder: (_, __) => Container(),
  );
}

// ignore: prefer_void_to_null
class TestAction extends Action<Null> {
  static const String serializationKey = 'test-action';

  final String? id;
  final Map<String, String>? props;

  TestAction({this.id, this.props}) : super(serializationKey: serializationKey);

  @override
  Widget buildLogActionWidget(
    BuildContext context,
    Persistence persistence, {
    Function()? onActionLogged,
  }) {
    return _someWidget('log-action');
  }

  Widget _someWidget(String idPrefix) {
    final key = getKey(idPrefix);
    return SizedBox(
      width: 100,
      height: 100,
      key: key,
      child: Text("$key"),
    );
  }

  Key getKey(String prefix) {
    return id == null ? UniqueKey() : Key("test-action-$prefix-$id");
  }

  @override
  Widget buildReminderListItem(BuildContext context, Reminder reminder) {
    return _someWidget('reminder-list-item');
  }

  @override
  Widget buildDetailsScreen(BuildContext context) {
    return _someWidget('details-screen');
  }

  @override
  String toString() {
    return "test action - $id - $props - $events";
  }

  @override
  bool operator ==(Object other) {
    if (other is! TestAction || other.runtimeType != runtimeType) {
      return false;
    }

    final serializationKeyEq =
        getSerializationKey() == other.getSerializationKey();
    final idEq = id == null
        // if id is null, check reference equality by calling `super.hashCode`
        ? super.hashCode == other.hashCode
        : id == other.id;
    final propsEq = mapEquals(props, other.props);
    final eventsEq = mapEquals(events, other.events);

    return serializationKeyEq && idEq && propsEq && eventsEq;
  }

  @override
  int get hashCode {
    var idHash = id == null ? super.hashCode : id.hashCode;

    return getSerializationKey().hashCode +
        idHash +
        props.hashCode +
        events.hashCode;
  }

  @override
  String get equalityKey => id ?? "unknown";

  @override
  Map<String, dynamic> subclassToJson() {
    return {
      "id": id,
      if (props != null) "props": jsonEncode(props),
    };
  }

  factory TestAction.fromJson(Map<String, dynamic> json) {
    return TestAction(
      id: json["id"],
      props: json["props"] == null
          ? null
          : Map<String, String>.from(jsonDecode(json["props"])),
    );
  }

  @override
  Null parseEventData(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  NotificationData getNotificationData() {
    return NotificationData(title: toString(), body: toString());
  }
}

@JsonSerializable()
class TestActionWithData extends Action<Data> {
  static const serializationKey = 'test-action-with-data';

  final String? id;

  TestActionWithData({this.id}) : super(serializationKey: serializationKey);

  @override
  String get equalityKey => 'action-with-event-data';

  @override
  Map<String, dynamic> subclassToJson() {
    return _$TestActionWithDataToJson(this);
  }

  factory TestActionWithData.fromJson(Map<String, dynamic> json) {
    return _$TestActionWithDataFromJson(json);
  }

  @override
  Data parseEventData(Map<String, dynamic> json) {
    return _$DataFromJson(json);
  }

  @override
  bool operator ==(Object other) {
    if (other is! TestActionWithData) {
      return false;
    }

    final eventsEq = mapEquals(events, other.events);

    if (id == null) {
      return eventsEq && hashCode == other.hashCode;
    } else {
      return eventsEq && id == other.id;
    }
  }

  @override
  int get hashCode {
    int hash = id == null ? super.hashCode : id.hashCode;
    hash += events.hashCode;

    return hash;
  }

  @override
  Widget buildLogActionWidget(
    BuildContext context,
    Persistence persistence, {
    Function()? onActionLogged,
  }) {
    throw UnimplementedError();
  }

  @override
  Widget buildReminderListItem(BuildContext context, Reminder reminder) {
    final lastEvent = getLastEvent();
    if (lastEvent == null) {
      return const Text("unknown");
    }

    final Data d = lastEvent.$2!;
    return Text(d.someProp);
  }

  @override
  Widget buildDetailsScreen(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  String toString() {
    return "$equalityKey - $id - $events";
  }

  @override
  NotificationData getNotificationData() {
    return NotificationData(title: toString(), body: toString());
  }
}

@JsonSerializable()
class Data extends SerializableEventData {
  final String someProp;

  Data(this.someProp);

  @override
  Map<String, dynamic> toJson() {
    return {
      'someProp': someProp,
    };
  }

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(json['someProp']);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Data) {
      return false;
    }

    return someProp == other.someProp;
  }

  @override
  int get hashCode => someProp.hashCode;

  @override
  String toString() {
    return "TestData{someProp=$someProp}";
  }
}
