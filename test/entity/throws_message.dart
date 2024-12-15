import 'package:flutter_test/flutter_test.dart';

ThrowsMessageMatcher throwsMessageContaining(String message) {
  return ThrowsMessageMatcher(".*$message.*");
}

class ThrowsMessageMatcher extends Matcher {
  final RegExp _expected;

  ThrowsMessageMatcher(String message)
      : _expected = RegExp(
          message,
          caseSensitive: false,
        );

  @override
  bool matches(item, Map matchState) {
    if (item is! Function) {
      throw ArgumentError('The actual value must be a function');
    }
    try {
      item();
      // If we get here, the function didn't throw at all.
      return false;
    } catch (e) {
      matchState['actual'] = e.toString();

      if (_expected.pattern.isEmpty) {
        // RegExp("") matches everything
        // `expect(() => throw('HELLO!'), throwsMessage(''));` passes but is not
        // what we want
        return false;
      }
      return _expected.hasMatch(e.toString());
    }
  }

  @override
  Description describe(Description description) {
    return description.add(
      'throws an exception with a message that matches "$_expected"',
    );
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final actual = matchState['actual'];
    if (actual == null) {
      return mismatchDescription.add('did not throw');
    }
    return mismatchDescription.add('got "$actual"');
  }
}
