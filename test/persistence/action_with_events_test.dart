import 'package:flutter_test/flutter_test.dart';
import 'package:poke/persistence/action_with_events.dart';

import '../utils/test-action/test_action.dart';

void main() {
  test('getLastEvent returns last event', () {
    final sut = ActionWithEvents.multiple(TestActionWithData(), {
      DateTime.parse('1963-11-26 01:02:03'): Data("first"),
      DateTime.parse('1963-11-27 01:02:03'): Data("second"),
      DateTime.parse('1963-11-28 01:02:03'): Data("third"),
    });

    expect(
        sut.getLastEvent(),
        equals(
          (
            DateTime.parse('1963-11-28 01:02:03'),
            Data('third'),
          ),
        ));
  });
}
