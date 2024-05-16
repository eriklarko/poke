import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/reminder_service/reminder_service.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/predictor/predictor.dart';

import '../utils/dependencies.dart';
import '../utils/test-action/test_action.dart';
import 'reminder_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Predictor>()])
void main() {
  registerTestActions();

  test('builds reminders for all actions', () async {
    final a1 = TestAction(id: '1');
    final a2 = TestAction(id: '2');
    final a3 = TestAction(id: '3');
    final dd1 = DateTime.parse('1963-11-23');
    final dd2 = DateTime.parse('1989-12-06');
    final dd3 = DateTime.parse('2005-03-26');

    final persistence = InMemoryPersistence();
    persistence.createAction(a1);
    persistence.createAction(a2);
    persistence.createAction(a3);
    setPersistence(persistence);

    final predictor = MockPredictor();
    when(predictor.predictNext(a1)).thenReturn(dd1);
    when(predictor.predictNext(a2)).thenReturn(dd2);
    when(predictor.predictNext(a3)).thenReturn(dd3);
    setDependency<Predictor>(predictor);

    final sut = ReminderService();
    await sut.init();
    expect(
      sut.getReminders(),
      equals([
        Reminder(action: a1, dueDate: dd1),
        Reminder(action: a2, dueDate: dd2),
        Reminder(action: a3, dueDate: dd3),
      ]),
    );
  });

  test('builds reminder for single action', () async {
    final a = TestAction(id: '1');
    final dd = DateTime.parse('1963-11-23');

    final persistence = InMemoryPersistence();
    persistence.createAction(a);
    setPersistence(persistence);

    final predictor = MockPredictor();
    when(predictor.predictNext(a)).thenReturn(dd);
    setDependency<Predictor>(predictor);

    final sut = ReminderService();
    expect(
      sut.buildReminder(a),
      equals(
        Reminder(action: a, dueDate: dd),
      ),
    );
  });

  // TODO: test getReminders returns updated reminder
  //   1. set up reminder service with one action
  //   2. update the action
  //   3. verify that getReminders returns the updated action and that the due date has been updated

  group('updates stream', () {
    ///////////////////////////////////////////////////////////////////////////
    // not part of these tests, but required for the end-to-end test to work //
    setDependency<Predictor>(MockPredictor());
    ///////////////////////////////////////////////////////////////////////////

    test('forwards updating events', () async {
      final persistence = InMemoryPersistence();
      setPersistence(persistence);

      final sut = ReminderService();
      await sut.init();
      expectLater(
        sut.updatesStream(),
        emitsInOrder([
          (e) => e.actionId == '1' && e.type == UpdateType.updating,
          (e) => e.actionId == '1' && e.type == UpdateType.added,
        ]),
      );

      // log action to trigger update event
      await persistence.logAction(TestAction(id: '1'), DateTime.now());
    });

    test('forwards delete events', () async {
      final persistence = InMemoryPersistence();
      setPersistence(persistence);

      final sut = ReminderService();
      await sut.init();
      expectLater(
        sut.updatesStream(),
        emitsInOrder([
          (e) => e.actionId == '1' && e.type == UpdateType.updating,
          (e) => e.actionId == '1' && e.type == UpdateType.removed,
        ]),
      );

      // trigger remove event
      //await persistence.deleteAction('1');
      fail('persistence.removeAction not implemented yet');
    });
  });
}
