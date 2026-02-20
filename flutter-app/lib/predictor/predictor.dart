import 'package:poke/models/action.dart';

abstract class Predictor {
  DateTime? predictNext(Action action);
}
