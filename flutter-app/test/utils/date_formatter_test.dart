import 'package:flutter_test/flutter_test.dart';
import 'package:poke/utils/date_formatter.dart';

void main() {
  test('formats date using 24h clock', () {
    final testDate = DateTime.parse('1963-11-26 13:14:15');
    expect(formatDate(testDate), equals('1963-11-26 13:14:15'));
  });

  test('ignores microseconds', () {
    final testDate =
        DateTime.parse('1963-11-26 13:14:15.16'); // note the .16 here

    expect(
      formatDate(testDate),
      equals('1963-11-26 13:14:15'), // .16 is missing
    );
  });
}
