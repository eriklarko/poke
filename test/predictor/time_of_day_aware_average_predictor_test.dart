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
}
