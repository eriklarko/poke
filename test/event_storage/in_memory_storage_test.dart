import 'package:flutter_test/flutter_test.dart';
import 'package:poke/event_storage/in_memory_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/test-action/test_action.dart';

import '../utils/clock.dart';

final clock = Clock();

void main() {
  test('logging actions allows reading them later', () async {
    final sut = InMemoryStorage();

    final Action a1 = TestAction(id: '1');
    final Action a2 = TestAction(id: '2');
    final ts1 = DateTime.parse('1963-11-26 01:02:03.456');
    final ts2 = DateTime.parse('1989-12-06 01:02:03.456');

    await sut.logAction(a1, ts1);
    await sut.logAction(a2, ts2);

    final expected = {
      a1: [ts1],
      a2: [ts2],
    };
    expect(
      await sut.getAll(),
      equals(expected),
    );
  });

  test('does not log the same event twice', () async {
    final sut = InMemoryStorage();
    final Action a = TestAction();

    final ts = DateTime.parse('1963-11-26 01:02:03.456');
    await sut.logAction(a, ts);
    await sut.logAction(a, ts);

    final expected = {
      a: [ts]
    };
    expect(
      await sut.getAll(),
      equals(expected),
    );
  });

  test('Groups plant events based on which plant was watered', () async {
    final eventStorage = InMemoryStorage();

    // create two different actions to be logged at different timestamps further
    // down
    final a1 = TestAction(id: '1');
    final a2 = TestAction(id: '2');

    // get references to the timestamps we're logging the actions at so that we
    // can check them later
    final ts1 = clock.next();
    final ts2 = clock.next();
    final ts3 = clock.next();

    // log the actions at their corresponding timestamps
    await eventStorage.logAction(a1, ts1);
    await eventStorage.logAction(a2, ts2);
    await eventStorage.logAction(a1, ts3);

    final expected = {
      a1: [ts1, ts3],
      a2: [ts2],
    };
    expect(
      await eventStorage.getAll(),
      equals(expected),
    );
  });
}
