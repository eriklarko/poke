import 'package:mockito/mockito.dart';

abstract class F<T> {
  void call(T t);
}

// MockCallback is a helper to test if a callback with a single parameter has
// been invoked or not in a test
//
// Example:
//
//  testWidgets('foo', (tester) async {
//    // Set up callback spy
//    final mockCallback = MockCallback<String>();
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
class MockCallback<T> extends Mock implements F<T> {}
