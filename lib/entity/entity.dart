// Represents something that actions are done to; a plant, a car, a house, etc.
import 'package:poke/entity/action.dart';
import 'package:poke/entity/json_utils.dart';

class Entity {
  // this is also the ID
  final String name;
  final Iterable<Action> actions;

  const Entity({
    required this.name,
    required this.actions,
  });

  String get id => name;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }

  factory Entity.fromJson(Map<String, dynamic> json) {
    final actionsRaw = grabRequiredValue<List>(json, 'actions');

    return Entity(
      name: grabRequiredValue<String>(json, 'name'),
      actions: actionsRaw.map((e) => Action.fromJson(e)),
    );
  }
}
