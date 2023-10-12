import 'package:flutter_test/flutter_test.dart';
import 'package:poke/models/event.dart';

void main() {
  test('id contains microseconds', () {
    final Event e =
        TestEvent(when: DateTime.parse('1963-11-26 01:02:03.456789'));
    expect(e.id, equals('TestEvent_19631126_010203_456'));
  });
}

class TestEvent extends Event {
  TestEvent({required super.when});

  @override
  Object getKey() {
    return this;
  }
}
