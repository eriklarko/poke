import 'package:flutter_test/flutter_test.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/predictor/average_predictor.dart';

import '../utils/test-action/test_action.dart';

void main() {
  test('predictNext predicts simple every 7 days cadence', () {
    final sut = AveragePredictor();

    // If you water a plant every Saturday you might have data like the following (Nov 23 1963 was a Saturday)
    //   * Watered on 1963-11-23 11:00
    //   * Watered on 1963-11-30 11:00 (Saturday the week after)
    //   * Watered on 1963-12-07 11:00 (Saturday the week after)
    //   * Watered on 1963-12-14 11:00 (Saturday the week after)
    //   * Watered on 1963-12-21 11:00 (Saturday the week after)
    final events = {
      DateTime.parse('1963-11-23 11:00'): null,
      DateTime.parse('1963-11-30 11:00'): null,
      DateTime.parse('1963-12-07 11:00'): null,
      DateTime.parse('1963-12-14 11:00'): null,
      DateTime.parse('1963-12-21 11:00'): null,
    };

    //   The pattern here is clear; the plant has been watered every 7 days, so we
    //   want to return `lastEvent + 7 days`
    final actual =
        sut.predictNext(ActionWithEvents.multiple(TestAction(), events));

    expect(actual, equals(DateTime.parse('1963-12-28 11:00')));
  });

  test('predictNext more complex case', () {
    final sut = AveragePredictor();

    // Given
    //   * Watered on 1963-11-23 11:00
    //   * Watered on 1963-11-30 12:00 (1h later on the Saturday the week after)
    //   * Watered on 1963-12-08 12:00 (Sunday the week after)
    final events = {
      DateTime.parse('1963-11-23 11:00'): null,
      DateTime.parse('1963-11-30 12:00'): null,
      DateTime.parse('1963-12-08 12:00'): null,
    };

    //   the time between the first two waterings is 7 days and 1h = 7*24 + 1 hours = 169 hours
    //   the time between the last  two waterings is 8 days = 192 hours
    //   averaging these two intervals gives us (169 + 192) / 2 = 180.5
    //   so we want to return `lastEvent + 180.5 hours`
    final actual =
        sut.predictNext(ActionWithEvents.multiple(TestAction(), events));

    expect(actual, equals(DateTime.parse('1963-12-16 00:30')));
  });
}
