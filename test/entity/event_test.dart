import 'package:flutter_test/flutter_test.dart';
import 'package:poke/entity/event.dart';

import 'throws_message.dart';

void main() {
  group('toJson', () {
    test('happy path', () {
      final json = Event(
        when: DateTime.parse('2023-10-01T12:00:00Z'),
        data: {'key': 'value'},
      ).toJson();

      expect(json, {
        'when': '2023-10-01T12:00:00.000Z',
        'data': {'key': 'value'},
      });
    });

    test('null data', () {
      final json = Event(
        when: DateTime.parse('2023-10-01T12:00:00Z'),
        data: null,
      ).toJson();

      expect(json, {
        'when': '2023-10-01T12:00:00.000Z',
      });
    });
  });

  group('fromJson', () {
    test('happy path', () {
      final event = Event.fromJson({
        'when': '2023-10-01T12:00:00.000Z',
        'data': {'key': 'value'},
      });

      expect(event.when, DateTime.parse('2023-10-01T12:00:00Z'));
      expect(event.data, {'key': 'value'});
    });

    test('invalid when', () {
      expect(
        () => Event.fromJson({
          'when': 'hello!',
          'data': null,
        }),
        throwsMessageContaining("invalid date format"),
      );
    });

    test('no when', () {
      expect(
        () => Event.fromJson({
          'data': {'key': 'value'},
        }),
        throwsMessageContaining("when missing"),
      );
    });

    test('no data', () {
      final event = Event.fromJson({
        'when': '2023-10-01T12:00:00.000Z',
      });

      expect(event.when, DateTime.parse('2023-10-01T12:00:00Z'));
      expect(event.data, null);
    });

    test('data is null', () {
      final event = Event.fromJson({
        'when': '2023-10-01T12:00:00.000Z',
        'data': null,
      });

      expect(event.when, DateTime.parse('2023-10-01T12:00:00Z'));
      expect(event.data, null);
    });

    test('data is not a map', () {
      expect(
        () => Event.fromJson({
          'when': '2023-10-01T12:00:00.000Z',
          'data': 'hello!',
        }),
        throwsMessageContaining(""),
      );
    });
  });
}
