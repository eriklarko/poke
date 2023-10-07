import 'package:flutter_test/flutter_test.dart';
import 'package:poke/event_storage/in_memory_storage.dart';
import 'package:poke/models/event.dart';

import '../models/event_test.dart';

void main() {
  test('adding events allows reading them later', () async {
    final sut = InMemoryStorage();
    final Event e1 = TestEvent(when: DateTime.parse('1963-11-26 01:02:03.456'));
    final Event e2 = TestEvent(when: DateTime.parse('1989-12-06 01:02:03.456'));

    await sut.addEvent(e1);
    await sut.addEvent(e2);

    final actual = await sut.getAll();
    final expected = {e1, e2};
    expect(actual, equals(expected));
  });

  test('does not add the same event twice', () async {
    final sut = InMemoryStorage();
    final Event e = TestEvent(when: DateTime.parse('1963-11-26 01:02:03.456'));

    await sut.addEvent(e);
    await sut.addEvent(e);

    final actual = await sut.getAll();
    final expected = {e};
    expect(actual, equals(expected));
  });
}
