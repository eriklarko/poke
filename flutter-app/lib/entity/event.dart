import 'package:poke/entity/json_utils.dart';

// An event is data around when an action was done to an entity; when a plant
// was watered and if it included fertilizer, when a car had its oil changed etc
class Event {
  final DateTime when;
  final Map<String, dynamic>? data;

  const Event({
    required this.when,
    this.data,
  });

  String get id => when.toUtc().toIso8601String();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'when': when.toUtc().toIso8601String(),
    };

    if (data != null) {
      json['data'] = data;
    }

    return json;
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    final whenRaw = grabRequiredValue<String>(json, 'when');

    return Event(
      when: DateTime.parse(whenRaw).toUtc(),
      data: json['data'],
    );
  }
}
