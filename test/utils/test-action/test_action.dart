import 'package:flutter/material.dart' hide Action;
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';
import 'package:poke/models/action.dart';

part 'test_action.g.dart';

void registerTestActions() {
  Action.registerSubclass(
    serializationKey: TestAction.serializationKey,
    type: TestAction,
    actionFromJson: TestAction.fromJson,
    eventDataFromJson: null,
  );

  Action.registerSubclass(
    serializationKey: TestActionWithData.serializationKey,
    type: TestActionWithData,
    actionFromJson: TestActionWithData.fromJson,
    eventDataFromJson: Data.fromJson,
  );
}

@JsonSerializable()
class TestAction extends Action<Null> {
  static const String serializationKey = 'test-action';

  final String? id;

  TestAction({this.id}) : super(serializationKey: serializationKey);

  @override
  Widget buildLogActionWidget(BuildContext context, (DateTime, void)? lastEvent,
      Persistence persistence) {
    throw UnimplementedError();
  }

  @override
  Widget buildReminderListItem(
      BuildContext context, (DateTime, Null)? lastEvent) {
    return SizedBox(
      width: 100,
      height: 100,
      key: id == null ? UniqueKey() : Key(id!),
      child: SizedBox(
        width: 100,
        height: 100,
        child: (id == null)
            ? const Text('reminder-test-action')
            : Text('reminder-test-action-$id'),
      ),
    );
  }

  @override
  String toString() {
    return "test action - $id";
  }

  @override
  bool operator ==(Object other) {
    if (other is! TestAction || other.runtimeType != runtimeType) {
      return false;
    }

    if (id == null) {
      return hashCode == other.hashCode;
    } else {
      return id == other.id;
    }
  }

  @override
  int get hashCode {
    if (id == null) {
      return super.hashCode;
    } else {
      return id.hashCode;
    }
  }

  @override
  String get equalityKey => id ?? "unknown";

  @override
  Map<String, dynamic> subclassToJson() {
    return _$TestActionToJson(this);
  }

  factory TestAction.fromJson(Map<String, dynamic> json) {
    return _$TestActionFromJson(json);
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
  bool operator ==(Object other) {
    if (other is! TestActionWithData) {
      return false;
    }

    if (id == null) {
      return hashCode == other.hashCode;
    } else {
      return id == other.id;
    }
  }

  @override
  int get hashCode {
    if (id == null) {
      return super.hashCode;
    } else {
      return id.hashCode;
    }
  }

  @override
  Widget buildLogActionWidget(BuildContext context, (DateTime, Data)? lastEvent,
      Persistence persistence) {
    throw UnimplementedError();
  }

  @override
  Widget buildReminderListItem(
      BuildContext context, (DateTime, Data)? lastEvent) {
    throw UnimplementedError();
  }
}

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
}
