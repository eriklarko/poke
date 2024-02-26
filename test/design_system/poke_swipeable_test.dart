import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/design_system/poke_swipeable.dart';
import 'package:poke/design_system/poke_text.dart';

import '../drag_directions.dart';
import '../mock_callback.dart';
import '../test_app.dart';

void main() {
  testWidgets('renders child', (tester) async {
    // render swipeable
    await pumpInTestApp(
      tester,
      PokeSwipeable<void>(
        swipeActions: const [],
        key: UniqueKey(),
        value: null,
        child: const PokeText('foo'),
      ),
    );

    expect(find.text('foo'), findsOneWidget);
  });

  testWidgets('renders swipe actions', (tester) async {
    final swipeActionCallback = MockSingleArgCallback();
    final swipeableKey = UniqueKey();

    // render swipeable
    await pumpInTestApp(
      tester,
      PokeSwipeable(
        key: swipeableKey,
        value: "foo",
        swipeActions: [
          (
            swipeActionCallback,
            const PokeText("swipe-action"),
          )
        ],
        child: const PokeText('foof'),
      ),
    );

    // swipe it a bit to reveal the swipe action
    await tester.drag(find.byKey(swipeableKey), endToStart);
    await tester.pumpAndSettle();

    // tap the swipe action and verify that its callback was invoked
    await tester.tap(find.text("swipe-action"));
    verify(swipeActionCallback("foo")).called(1);
  });
}
