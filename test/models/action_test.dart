import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/test-action/test_action.dart';

void main() {
  test('can be serialized', () {
    final Action sut = TestAction(id: '1');

    final String json = jsonEncode(sut.toJson());
    expect(
      json,
      equals(
        '{"serializationKey":"test-action","id":"1"}',
      ),
    );
  });

  test('can be deserialized', () {
    const String json = '{"serializationKey":"test-action","id":"1"}';
    final Map<String, dynamic> decodedJson = jsonDecode(json);
    expect(
      Action.fromJson(decodedJson),
      equals(
        TestAction(id: '1'),
      ),
    );
  });
}
