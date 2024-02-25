import 'package:mockito/mockito.dart';

abstract class NoArgF {
  void call();
}

// See comment on MockSingleArgCallback
class MockNoArgCallback extends Mock implements NoArgF {}

abstract class SingleArgF<T> {
  void call(T t);
}

// MockSingleArgCallback is a helper to test if a callback with a single
// parameter has been invoked or not in a test
//
// Example:
//
//  testWidgets('foo', (tester) async {
//    // Set up callback spy
//    final mockCallback = MockSingleArgCallback<String>();
//
//    // Render test widget
//    await pumpInTestApp(
//      tester,
//      GestureDetector(
//        onTap: () {
//          mockCallback('tap');
//        },
//        child: const Text('foo'),
//      ),
//    );
//
//    // Tap test widget
//    await tester.tap(find.byType(GestureDetector));
//
//    // Assert that the onTap callback was invoked once with 'tap' as argument
//    verify(mockCallback('tap')).called(1);
//  });
class MockSingleArgCallback<T> extends Mock implements SingleArgF<T> {}

class MockTwoArgCallback<T, U> extends Mock {
  void call(T t, U u);
}
