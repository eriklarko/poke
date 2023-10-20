import 'package:flutter_test/flutter_test.dart';
import 'package:poke/event_storage/silly_string_storage.dart';
import 'package:poke/models/test-action/test_action.dart';

void main() {
  // this is a bit of a strange test... It really only tests that actions logged can be read back again, but what I really want to test is that
  test('Events can be serialized and deserialized again', () async {
    final eventStorage = SillyStringStorage();

    final testAction = TestAction(id: 'hello');
    final ts = DateTime.parse('1963-11-26 01:02:03.456');

    // log action happened at `ts`
    await eventStorage.logAction(testAction, ts);

    // read all logged actions, aka events
    final events = await eventStorage.getAll();

    expect(
      events,
      equals({
        testAction: [ts],
      }),
    );
  });
}
