import 'package:poke/models/action.dart';
import 'package:poke/utils/date_formatter.dart';

// An event is when an action was performed, like watering a plant or changing
// AC filter.
class Event<ActionType extends Action> {
  final ActionType action;
  final DateTime when;

  Event({required this.action, required this.when});

  @override
  String toString() {
    return "$action at ${formatDate(when)}";
  }

  @override
  bool operator ==(Object other) =>
      other is Event &&
      other.runtimeType == runtimeType &&
      other.action == action &&
      other.when == other.when;

  @override
  int get hashCode => action.hashCode + when.hashCode;
}
