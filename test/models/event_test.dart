import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/event.dart';
import 'package:poke/models/test-action/test_action.dart';

void main() {
  test('can be serialized', () {
    final Action action = TestAction(id: '1');
    final ts = DateTime.parse('1963-11-26 01:02:03.456');

    final Event sut = Event(action: action, when: ts);
    final String json = jsonEncode(sut.toJson());
    expect(
      json,
      equals(
        '{"action":{"serializationKey":"test-action","id":"1"},"when":"1963-11-26T01:02:03.456"}',
      ),
    );
  });

  test('can be deserialized', () {
    const String json =
        '{"action":{"serializationKey":"test-action","id":"1"},"when":"1963-11-26T01:02:03.456"}';
    final Map<String, dynamic> decodedJson = jsonDecode(json);
    expect(
      Event.fromJson(decodedJson),
      equals(
        Event(
          action: TestAction(id: '1'),
          when: DateTime.parse('1963-11-26 01:02:03.456'),
        ),
      ),
    );
  });
}
