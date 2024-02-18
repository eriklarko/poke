import 'package:flutter/material.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/predictor/average_predictor.dart';
import 'package:poke/predictor/predictor.dart';

// The straight forward algorithm described in AveragePredictor is technically
// pretty good, but can give predictions in the middle of the night, even if
// the plant was always watered during the day. This algorithm is a slight
// modification to the original that tries to predict a better time of day.
class TimeOfDayAwareAveragePredictor extends Predictor {
  final _averagePredictor = AveragePredictor();

  @override
  DateTime? predictNext(ActionWithEvents actionWithEvents) {
    final avgPrediction = _averagePredictor.predictNext(actionWithEvents);
    if (avgPrediction == null) {
      return null;
    }

    final predictedDate = DateUtils.dateOnly(avgPrediction);
    final predictedTimeOfDay =
        _findMostCommonTimeOfDay(actionWithEvents.events.keys);

    return predictedDate.add(predictedTimeOfDay);
  }

  Duration _findMostCommonTimeOfDay(Iterable<DateTime> occurrences) {
    // this would probably work best by using a clustering algorithm, but yeah..
    // instead it's finding the mode

    // convert occurrences to times of day
    final tods = occurrences.map((dt) => Duration(
          hours: dt.hour,

          // since the minute might vary too much for the mode calculation to
          // work properly we find the closest quarter hour and use that instead
          //
          // this does not put 11:59 and 12:01 in the same bucket unfortunately, but it's simple
          minutes: _findClosest(dt.minute, [0, 15, 30, 45]),
        ));

    // and then find the mode in the time-of-day array
    return _findMode(tods);
  }

  int _findClosest(int needle, List<int> validValues) {
    int smallestDiff =
        -1 >>> 1; // this is int max https://stackoverflow.com/a/75928881
    int closest = validValues.first;
    for (final validValue in validValues) {
      final diff = (validValue - needle).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        closest = validValue;
      }
    }

    return closest;
  }

  T _findMode<T>(Iterable<T> items) {
    // start by counting the number each item occurs in the array
    Map<T, int> counts = {};
    for (final item in items) {
      counts.update(
        item,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    // then find the max
    int maxCount = 0;
    T maxT = items.first;
    counts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        maxT = key;
      }
    });

    return maxT;
  }
}
