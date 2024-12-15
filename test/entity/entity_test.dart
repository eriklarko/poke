import 'package:flutter_test/flutter_test.dart';
import 'package:poke/entity/action.dart';
import 'package:poke/entity/entity.dart';
import 'package:poke/entity/event.dart';

void main() {
  group('toJson', () {
    test('happy path', () {
      final json = Entity(
        name: 'Frank the plant',
        actions: [Action(name: 'Water')],
      ).toJson();

      expect(json, {
        'name': 'Frank the plant',
        'actions': [
          {'name': 'Water', 'events': []},
        ],
      });
    });

    test('toJson without actions', () {
      final json = Entity(
        name: 'Frank the plant',
        actions: [],
      ).toJson();

      expect(json, {
        'name': 'Frank the plant',
        'actions': [],
      });
    });

    test('toJson with actions and events', () {
      final json = Entity(
        name: 'Frank the plant',
        actions: [
          Action(
            name: 'Water',
            events: [
              Event(
                when: DateTime.parse('1963-11-26'),
                data: {'usedFertilizer': 'true'},
              ),
              Event(
                when: DateTime.parse('1989-12-06'),
                data: {'usedFertilizer': 'false'},
              ),
            ],
          ),
        ],
      ).toJson();

      expect(json, {
        'name': 'Frank the plant',
        'actions': [
          {
            'name': 'Water',
            'events': [
              {
                'when': '1963-11-26T00:00:00.000',
                'data': {'usedFertilizer': 'true'},
              },
              {
                'when': '1989-12-06T00:00:00.000',
                'data': {'usedFertilizer': 'false'},
              },
            ],
          },
        ],
      });
    });
  });

  group('fromJson', () {
    test('with actions', () {
      final entity = Entity.fromJson({
        'name': 'Frank the plant',
        'actions': [
          {'name': 'Water'},
          {'name': 'Repot'},
        ],
      });

      expect(entity.name, 'Frank the plant');
      expect(entity.actions.length, 2);
      expect(entity.actions.first.name, 'Water');
      expect(entity.actions.skip(1).first.name, 'Repot');
    });

    test('without actions', () {
      final entity = Entity.fromJson({
        'name': 'Frank the plant',
        'actions': [],
      });

      expect(entity.name, 'Frank the plant');
      expect(entity.actions.isEmpty, true);
    });

    test('with actions and events', () {
      final entity = Entity.fromJson({
        'name': 'Frank the plant',
        'actions': [
          {
            'name': 'Water',
            'events': [
              {
                'when': '1963-11-26T00:00:00.000',
                'data': {'usedFertilizer': 'true'},
              },
              {
                'when': '1989-12-06T00:00:00.000',
                'data': {'usedFertilizer': 'false'},
              },
            ],
          },
        ],
      });

      expect(entity.name, 'Frank the plant');
      expect(entity.actions.length, 1);
      expect(entity.actions.first.name, 'Water');
      expect(entity.actions.first.events.length, 2);

      final firstEvent = entity.actions.first.events.first;
      expect(firstEvent.when, DateTime.parse('1963-11-26'));
      expect(firstEvent.data, {'usedFertilizer': 'true'});

      final secondEvent = entity.actions.first.events.skip(1).first;
      expect(secondEvent.when, DateTime.parse('1989-12-06'));
      expect(secondEvent.data, {'usedFertilizer': 'false'});
    });
  });
}
