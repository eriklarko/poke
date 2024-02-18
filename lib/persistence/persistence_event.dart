import 'package:flutter/widgets.dart';
import 'package:poke/utils/key_factory.dart';

sealed class PersistenceEvent {
  final String actionId;

  PersistenceEvent({required this.actionId});

  static Updating updating({required String actionId}) => Updating(actionId);

  static FinishedUpdating finished(Updating u) => FinishedUpdating(u);

  @override
  int get hashCode => actionId.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    if (other is! PersistenceEvent) {
      return false;
    }

    return actionId == other.actionId;
  }

  @override
  String toString() {
    return "$runtimeType - $actionId";
  }
}

class Updating extends PersistenceEvent {
  final GlobalKey key = KeyFactory.newGlobalKey();

  Updating(String actionId) : super(actionId: actionId);

  @override
  int get hashCode => super.hashCode + key.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! Updating) {
      return false;
    }

    return super == other && key == other.key;
  }

  @override
  String toString() {
    return super.toString() + " - $key";
  }
}

class FinishedUpdating extends PersistenceEvent {
  final Updating updatingEvent;

  FinishedUpdating(
    this.updatingEvent,
  ) : super(actionId: updatingEvent.actionId);

  @override
  int get hashCode => super.hashCode + updatingEvent.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! FinishedUpdating) {
      return false;
    }

    return super == other && updatingEvent == other.updatingEvent;
  }

  @override
  String toString() {
    return super.toString() + " - $updatingEvent";
  }
}
