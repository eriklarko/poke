// An event is when an action was performed, like watering a plant or changing
// AC filter.
abstract class Event {
  final DateTime when;

  Event({required this.when});
}
