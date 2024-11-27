import 'package:flutter_test/flutter_test.dart';
import 'package:poke/predictor/time_of_day_aware_average_predictor.dart';

import '../utils/test-action/test_action.dart';

void main() {
  test('has a more reasonable time-of-day than the average predictor', () {
    final sut = TimeOfDayAwareAveragePredictor();

    // Given
    //   * Watered on 1963-11-23 11:00
    //   * Watered on 1963-11-30 12:00 (1h later on the Saturday the week after)
    //   * Watered on 1963-12-08 12:00 (Sunday the week after)
    final events = {
      DateTime.parse('1963-11-23 11:11'): null,
      DateTime.parse('1963-11-30 12:06'): null,
      DateTime.parse('1963-12-08 12:04'): null,
    };

    //   the time between the first two waterings is 7 days and 1h = 7*24 + 1 hours = 169 hours
    //   the time between the last  two waterings is 8 days = 192 hours
    //   averaging these two intervals gives us (169 + 192) / 2 = 180.5
    //   so we want to return `lastEvent + 180.5 hours`
    final actual = sut.predictNext(TestAction().withEvents(events));

    expect(actual, equals(DateTime.parse('1963-12-16 12:00')));
  });

  test('handles events out of order', () {
    final sut = TimeOfDayAwareAveragePredictor();

    // Create a few events with the dates out of order
    final events = {
      DateTime.parse("2024-07-31 10:09:49.015978"): null,
      DateTime.parse("2024-06-12 12:34:30.688859"): null,
      DateTime.parse("2024-09-23 07:43:02.594552"): null,
      DateTime.parse("2024-03-21 16:44:48.525724"): null,
      DateTime.parse("2024-11-10 09:14:26.222424"): null,
      DateTime.parse("2024-05-02 11:49:36.620409"): null,
    };
    final actual = sut.predictNext(TestAction().withEvents(events));

    // The prediction should be after the last event
    final sortedEvents = events.keys.toList()..sort();
    expect(actual!.isAfter(sortedEvents.last), isTrue);
  });
}
