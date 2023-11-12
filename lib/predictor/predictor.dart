import 'package:poke/event_storage/action_with_events.dart';

abstract class Predictor {
  DateTime predictNext(ActionWithEvents actionWithEvents);
}
