import 'package:poke/event_storage/action_with_events.dart';
import 'package:poke/predictor/predictor.dart';

class AveragePredictor extends Predictor {
  @override
  DateTime predictNext(ActionWithEvents actionWithEvents) {
    final previousOccurrances = List.of(actionWithEvents.events.keys);
    return _predictNext(DateTime.now(), previousOccurrances);
  }

  // predictNext takes a list of event timestamps and returns when the next event
  // should occur to fit the cadence of previous occurrances.
  //
  // If you water a plant every Saturday you might have data like the following (Nov 23 1963 was a Saturday)
  //   * Watered on 1963-11-23 11:00
  //   * Watered on 1963-11-30 11:00 (Saturday the week after)
  //   * Watered on 1963-12-06 11:00 (Saturday the week after)
  //   * Watered on 1963-12-13 11:00 (Saturday the week after)
  //   * Watered on 1963-12-20 11:00 (Saturday the week after)
  //
  //   The pattern here is clear; the plant has been watered every 7 days, so we
  //   want to return `currenTime + 7 days`
  //
  // In reality, the time of day and the exact cadence won't be so clear, but the
  // idea is to use the average cadence to calculate when to water the plant next
  // time.
  //
  // Given
  //   * Watered on 1963-11-23 11:00
  //   * Watered on 1963-11-30 12:00 (1h later on the Saturday the week after)
  //   * Watered on 1963-12-07 12:00 (Sunday the week after)
  //
  //   the time between the first two waterings is 7 days and 1h = 7*24 + 1 hours = 169 hours
  //   the time between the last  two waterings is 8 days = 192 hours
  //   averaging these two intervals gives us (169 + 192) / 2 = 180.5
  //   so we want to return `currentTime + 180.5 hours`
  DateTime _predictNext(
    DateTime currentTime,
    List<DateTime> previousOccurrances,
  ) {
    return DateTime.now();
  }
}
