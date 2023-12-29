import 'package:poke/persistence/action_with_events.dart';

abstract class Predictor {
  DateTime? predictNext(ActionWithEvents actionWithEvents);
}
