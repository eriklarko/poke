import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// pumpInTestAppFactory is used to ensure a widget under test has the context
// flutter needs to properly render it. Seems like this should be part of the
// stdlib, no? :old-man-yells-at-clouds:
//
// It helps with the following
//   * Renders the widget under test in a `MaterialApp` so that flutter can
//     figure out if text should be rendered rtl or ltr
//   * Wraps the widget under test in `Flex` to enable testing widget with
//     `Expanded` in it's tree
//
// It is also designed to allow you to add any extra wrappers you need for your
// specific test. If you're testing a ListBuilder for example it has be wrapped
// in `Expanded(...)` for the test to work, but adding it in all tests makes it
// harder to see what is being tested. This factory function comes to the
// rescue.
//
// Example:
//  final testApp = pumpInTestAppFactory(
//    (widgetUnderTest) => Expanded(
//      child: widgetUnderTest,
//    ),
//  );
//
//  testWidgets('list items are rendered', (widgetTester) async {
//    await testApp(
//      widgetTester,
//      ListView.builder(
//        itemCount: 3,
//        itemBuilder: (context, index) => Text("hello world $index"),
//      ),
//    );
//    expect(find.text("hello world 0"), findsOneWidget);
//    expect(find.text("hello world 1"), findsOneWidget);
//    expect(find.text("hello world 2"), findsOneWidget);
//  });
Future<void> Function(WidgetTester, Widget) pumpInTestAppFactory(
  Widget Function(Widget) widgetUnderTestWrapper,
) {
  return (
    WidgetTester tester,
    Widget widgetUnderTest,
  ) async {
    final app = MaterialApp(
      title: 'why the flying fudge do we need this shit?',
      home: Scaffold(
        body: widgetUnderTestWrapper(widgetUnderTest),
      ),
    );

    await tester.pumpWidget(app);
  };
}

// If you don't need any fancy wrappings, you can use this simpler version
//
// Example:
//  testWidgets('string is rendered', (widgetTester) async {
//    await pumpInTestApp(widgetTester, Text("hello world"));
//    expect(find.text("hello world"), findsOneWidget);
//  });
Future<void> pumpInTestApp(WidgetTester tester, Widget w) {
  final testAppFactory = pumpInTestAppFactory(
    (widgetUnderTest) => widgetUnderTest,
  );
  return testAppFactory(tester, w);
}
