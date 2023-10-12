import 'package:intl/intl.dart';

// date formatter used to generate event id. More precision is better.
final DateFormat formatter = DateFormat('yyyyMMdd_HHmmss_SSS');

// An event is when an action was performed, like watering a plant or changing
// AC filter.
abstract class Event {
  final DateTime when;

  Event({required this.when});

  Object getKey();

  // The event type together with the time the event occured (`this.when`) is
  // used to uniquely identify an event.
  String get id => "${runtimeType}_${formatter.format(when)}";
}
