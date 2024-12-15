import 'package:flutter_test/flutter_test.dart';
import 'package:poke/entity/action.dart';
import 'package:poke/entity/event.dart';

import 'throws_message.dart';

void main() {
  group('toJson', () {
    test('happy path', () {
      final json = Action(
        name: 'Test Action',
        events: [
          Event(when: DateTime.parse('1963-11-23'), data: {'key1': 'value1'}),
          Event(when: DateTime.parse('1989-12-06'), data: {'key2': 'value2'}),
        ],
      ).toJson();

      expect(json['name'], 'Test Action');
      expect(
        json['events'],
        equals([
          {
            'when': '1963-11-23T00:00:00.000',
            'data': {'key1': 'value1'},
          },
          {
            'when': '1989-12-06T00:00:00.000',
            'data': {'key2': 'value2'},
          },
        ]),
      );
    });

    test('no data in events', () {
      final json = Action(
        name: 'Test Action',
        events: [
          Event(when: DateTime.parse('1963-11-23')),
          Event(when: DateTime.parse('1989-12-06')),
        ],
      ).toJson();

      expect(json['name'], 'Test Action');
      expect(
        json['events'],
        equals([
          {'when': '1963-11-23T00:00:00.000'},
          {'when': '1989-12-06T00:00:00.000'},
        ]),
      );
    });

    test('no events', () {
      final json = Action(name: 'Test Action').toJson();

      expect(json['name'], 'Test Action');
      expect(json['events'], equals([]));
    });
  });

  group('fromJson', () {
    test('happy path', () {
      final action = Action.fromJson({
        'name': 'Test Action',
        'events': [
          {
            'when': '1963-11-23',
            'data': {'key1': 'value1'},
          },
          {
            'when': '1989-12-06',
            'data': {'key2': 'value2'},
          },
        ],
      });

      expect(action.name, 'Test Action');

      expect(action.events, hasLength(2));

      final firstEvent = action.events.first;
      expect(firstEvent.when, DateTime.parse('1963-11-23'));
      expect(firstEvent.data, {'key1': 'value1'});

      final secondEvent = action.events.skip(1).first;
      expect(secondEvent.when, DateTime.parse('1989-12-06'));
      expect(secondEvent.data, {'key2': 'value2'});
    });

    test('should handle missing events', () {
      final action = Action.fromJson({
        'name': 'Test Action',
      });

      expect(action.name, 'Test Action');
      expect(action.events, isEmpty);
    });

    test('should handle null events', () {
      final action = Action.fromJson({
        'name': 'Test Action',
        'events': null,
      });

      expect(action.name, 'Test Action');
      expect(action.events, isEmpty);
    });

    test('should throw an error if name is missing', () {
      expect(
        () => Action.fromJson({
          'events': [
            {
              'when': '1963-11-23T00:00:00.000',
              'data': {'key1': 'value1'}
            },
          ],
        }),
        throwsMessageContaining("name missing"),
      );
    });
  });
}
