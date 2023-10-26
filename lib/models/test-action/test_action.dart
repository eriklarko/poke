import 'package:flutter/material.dart' hide Action;
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/models/action.dart';

part 'test_action.g.dart';

// This class is only used by tests, but because of how JSON serialization works
// it has to be accessible to the Event class, and thus cannot be in the test
// folder :old-man-yells-at-coulds:
@JsonSerializable()
class TestAction extends Action {
  final String? id;

  TestAction({this.id}) : super(serializationKey: 'test-action');

  @override
  Widget buildLogActionWidget(BuildContext context, EventStorage eventStorage) {
    throw UnimplementedError();
  }

  @override
  Widget buildReminderListItem(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      key: id == null ? UniqueKey() : Key(id!),
      child: (id == null)
          ? const Text('reminder-test-action')
          : Text('reminder-test-action-$id'),
    );
  }

  @override
  String toString() {
    return "$serializationKey - $id";
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
  Map<String, dynamic> toJson() {
    return _$TestActionToJson(this);
  }

  factory TestAction.fromJson(Map<String, dynamic> json) {
    return _$TestActionFromJson(json);
  }
}
