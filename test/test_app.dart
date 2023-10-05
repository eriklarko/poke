import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// wrapInTestApp is used to ensure a widget under test has the context flutter
// needs to properly render it. Seems like this should be part of the stdlib,
// no? :old-man-yells-at-clouds:
//
// It does the following
//   * Renders the widget under test in a `MaterialApp` so that flutter can
//     figure out if text should be rendered rtl or ltr
//   * Wraps the widget under test in `Flex` to enable testing widget with
//     `Expanded` in it's tree
Widget wrapInTestApp(Widget widgetUnderTest) {
  return MaterialApp(
    title: 'foo',
    home: Flex(
      direction: Axis.vertical,
      children: [widgetUnderTest],
    ),
  );
}

Future<void> pumpInTestApp(WidgetTester tester, Widget w) {
  return tester.pumpWidget(wrapInTestApp(w));
}
