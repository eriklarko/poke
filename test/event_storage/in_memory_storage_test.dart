import 'package:flutter_test/flutter_test.dart';
import 'package:poke/event_storage/in_memory_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/event.dart';
import 'package:poke/models/test-action/test_action.dart';

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
      Event(action: a1, when: ts1),
      Event(action: a2, when: ts2)
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

    final expected = {Event(action: a, when: ts)};
    expect(
      await sut.getAll(),
      equals(expected),
    );
  });
}
