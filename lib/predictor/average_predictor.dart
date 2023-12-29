import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/predictor/predictor.dart';

class AveragePredictor extends Predictor {
  @override
  DateTime predictNext(ActionWithEvents actionWithEvents) {
    final previousOccurrences = List.of(actionWithEvents.events.keys);
    return _predictNext(previousOccurrences);
  }

  // predictNext takes a list of event timestamps and returns when the next event
  // should occur to fit the cadence of previous occurrences.
  //
  // If you water a plant every Saturday you might have data like the following (Nov 23 1963 was a Saturday)
  //   * Watered on 1963-11-23 11:00
  //   * Watered on 1963-11-30 11:00 (Saturday the week after)
  //   * Watered on 1963-12-07 11:00 (Saturday the week after)
  //   * Watered on 1963-12-14 11:00 (Saturday the week after)
  //   * Watered on 1963-12-21 11:00 (Saturday the week after)
  //
  //   The pattern here is clear; the plant has been watered every 7 days, so we
  //   want to return `lastEvent + 7 days = 1963-12-28 11:00`
  //
  // In reality, the time of day and the exact cadence won't be so clear, but the
  // idea is to use the average cadence to calculate when to water the plant next
  // time.
  //
  // Given
  //   * Watered on 1963-11-23 11:00
  //   * Watered on 1963-11-30 12:00 (1h later on the Saturday the week after)
  //   * Watered on 1963-12-08 12:00 (Sunday the week after)
  //
  //   the time between the first two waterings is 7 days and 1h = 7*24 + 1 hours = 169 hours
  //   the time between the last  two waterings is 8 days = 192 hours
  //   averaging these two intervals gives us (169 + 192) / 2 = 180.5
  //   so we want to return `lastEvent + 180.5 hours = 1963-12-16 00:30`
  DateTime _predictNext(
    List<DateTime> previousOccurrences,
  ) {
    if (previousOccurrences.length < 2) {
      // CANNOT CALCULATE
      throw "Not enough data";
    }

    Duration avgTimeBetweenOccurrences =
        _calculateAverageTimeBetweenOccurrences(previousOccurrences);

    final lastEvent = previousOccurrences.last;
    return lastEvent.add(avgTimeBetweenOccurrences);
  }

  Duration _calculateAverageTimeBetweenOccurrences(List<DateTime> occurrences) {
    // Start by summing up the time between each occurrence in milliseconds
    // note the i=1 start in the for loop
    Duration diffSum = Duration.zero;
    for (int i = 1; i < occurrences.length; i++) {
      Duration diff = occurrences[i].difference(occurrences[i - 1]).abs();
      diffSum += diff;
    }

    // And divide by number of differences
    return diffSum ~/ (occurrences.length - 1);
  }
}
