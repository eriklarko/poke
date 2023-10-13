import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/event_storage/event_storage.dart';
import 'package:poke/event_storage/in_memory_storage.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/event.dart';

void main() {
  test('logging actions allows reading them later', () async {
    final sut = InMemoryStorage();

    final Action a1 = TestAction();
    final Action a2 = TestAction();
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

class TestAction extends Action {
  @override
  Widget buildReminderListItem(BuildContext context) {
    // TODO: implement buildReminderListItem
    throw UnimplementedError();
  }

  @override
  Widget buildLogActionWidget(BuildContext context, EventStorage eventStorage) {
    // TODO: implement buildLogActionWidget
    throw UnimplementedError();
  }
}
