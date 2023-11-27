import 'package:flutter_test/flutter_test.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/persistence/reminder_builder.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/predictor/predictor.dart';

import '../utils/clock.dart';
import '../utils/test-action/test_action.dart';

void main() {
  test('reminds about existing events', () async {
    final persistence = InMemoryPersistence();
    final DateTime predictedTime = DateTime.parse('1963-11-26 01:02:03');
    final predictor = MockPredictor.static(predictedTime);

    final action = TestAction(id: '1');
    final ts = DateTime.now();
    await persistence.logAction(action, ts);

    expect(
      await buildReminders(persistence, predictor),
      equals([
        Reminder(
          actionWithEvents: ActionWithEvents.single(action, ts),
          dueDate: predictedTime,
        ),
      ]),
    );
  });
}

class MockPredictor implements Predictor {
  final Clock? clock;
  final DateTime? staticTime;

  MockPredictor.static(this.staticTime) : clock = null;
  MockPredictor.withClock({this.clock}) : staticTime = null;

  @override
  DateTime predictNext(ActionWithEvents actionWithEvents) {
    return clock?.next() ?? staticTime ?? DateTime.now();
  }
}
