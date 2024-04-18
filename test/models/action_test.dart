import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/models/action.dart';

import '../utils/test-action/test_action.dart';

void main() {
  group('actions with data', () {
    test('serializes as expected', () {
      final TestActionWithData sut = TestActionWithData(id: '1');
      final dt = DateTime.parse("1963-11-23");
      final Data data = Data("some-value");
      sut.withEvents({dt: data});

      expect(
        sut.toJson(),
        equals({
          'serializationKey': 'test-action-with-data',
          'id': '1',
          'events': {
            dt.toIso8601String(): {'someProp': 'some-value'},
          },
        }),
      );
    });

    test('deserializes as expected', () {
      Action.registerSubclass(
        serializationKey: 'test-action-with-data',
        actionFromJson: TestActionWithData.fromJson,
        newInstanceBuilder: (_, __) => Container(),
      );

      final dt = DateTime.parse("1963-11-23");
      final Map<String, dynamic> json = {
        'serializationKey': 'test-action-with-data',
        'id': '1',
        'events': {
          dt.toIso8601String(): {'someProp': 'some-value'},
        },
      };

      expect(
        Action.fromJson(json),
        equals(
          TestActionWithData(id: '1').withEvents({dt: Data('some-value')}),
        ),
      );
    });

    test('getLastEvent returns last event', () {
      final sut = TestActionWithData(id: "1").withEvents({
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
        ),
      );
    });

    test('remove event', () {
      final dtToRemove = DateTime.parse('1963-11-27 01:02:03');
      final sut = TestActionWithData(id: "1").withEvents({
        DateTime.parse('1963-11-26 01:02:03'): Data('some-value'),
        dtToRemove: Data('some-other-value'),
      });

      sut.removeEvent(dtToRemove);

      expect(
        sut.events,
        equals({DateTime.parse('1963-11-26 01:02:03'): Data('some-value')}),
      );
    });
  });

  group('actions without data', () {
    test('serializes as expected', () {
      final TestAction sut = TestAction(id: '1');
      final dt = DateTime.parse("1963-11-23");
      sut.withEvent(dt);

      expect(
        sut.toJson(),
        equals({
          'serializationKey': 'test-action',
          'id': '1',
          'events': {
            dt.toIso8601String(): null,
          },
        }),
      );
    });

    test('deserializes as expected', () {
      Action.registerSubclass(
        serializationKey: 'test-action',
        actionFromJson: TestAction.fromJson,
        newInstanceBuilder: (_, __) => Container(),
      );

      final dt = DateTime.parse("1963-11-23");
      final Map<String, dynamic> json = {
        'serializationKey': 'test-action',
        'id': '1',
        'events': {
          dt.toIso8601String(): null,
        },
      };

      expect(
        Action.fromJson(json),
        equals(
          TestAction(id: '1').withEvent(dt),
        ),
      );
    });

    test('getLastEvent returns last event', () {
      final sut = TestAction(id: "1").withEvents({
        DateTime.parse('1963-11-26 01:02:03'): null,
        DateTime.parse('1963-11-27 01:02:03'): null,
        DateTime.parse('1963-11-28 01:02:03'): null,
      });

      expect(
        sut.getLastEvent(),
        equals(
          (DateTime.parse('1963-11-28 01:02:03'), null),
        ),
      );
    });

    test('remove event', () {
      final dtToRemove = DateTime.parse('1963-11-27 01:02:03');
      final sut = TestAction(id: "1").withEvents({
        DateTime.parse('1963-11-26 01:02:03'): null,
        dtToRemove: null,
      });

      sut.removeEvent(dtToRemove);

      expect(
        sut.events,
        equals({DateTime.parse('1963-11-26 01:02:03'): null}),
      );
    });
  });
}
