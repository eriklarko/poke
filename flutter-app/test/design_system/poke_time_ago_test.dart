import 'package:flutter_test/flutter_test.dart';
import 'package:poke/design_system/poke_time_ago.dart';

import '../test_app.dart';

void main() {
  final testCases = {
    "4 days ago": {
      "expected": "4 days ago",
      "date": DateTime.now().subtract(Duration(days: 4)),
    },
    //
    "yesterday,simplest": {
      "expected": "yesterday",
      "date": DateTime.now().subtract(Duration(days: 1)),
    },
    //
    "tomorrow, simplest": {
      "expected": "tomorrow",
      "date": DateTime.now().add(Duration(days: 1)),
    },
  };

  testCases.forEach((name, testCase) {
    testWidgets('poke time ago $name', (tester) async {
      String? actual = null;
      await pumpInTestApp(
        tester,
        PokeTimeAgo(
          date: testCase["date"] as DateTime,
          now: testCase["_now"] as DateTime?,
          format: (timeAgo) {
            // it's hard to write a test widget test with
            //   `expect(find.text(expected), findsOneWidget);`
            // that prints what the widget is actually rendering
            // instead we hack it.
            actual = timeAgo;
            return timeAgo;
          },
        ),
      );

      expect(actual, testCase["expected"] as String);
    });
  });
}
