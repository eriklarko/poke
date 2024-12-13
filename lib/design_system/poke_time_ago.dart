import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class PokeTimeAgo extends StatelessWidget {
  static bool _initialized = false;
  static void _initialize() {
    if (_initialized) return;
    _initialized = true;

    setLocaleMessages("poke-en-past", PokeEnPastMessages());
    setLocaleMessages("poke-en-future", PokeEnFutureMessages());
  }

  final DateTime date;

  // `format` can be used to prepend/append things to the `15 minutes ago` string
  // ex:
  //  PokeTimeAgo({
  //    ...
  //    format: (timeAgo)=> "Watered $timeAgo"},
  //  );
  //
  //  shows something like "Watered four days ago".
  final String Function(String timeAgo)? format;

  final TextStyle textStyle;

  // used to determine the current time in a testable way
  final DateTime now;

  PokeTimeAgo({
    super.key,
    required this.date,
    this.format,
    this.textStyle = finePrint,
    DateTime? now,
  }) : now = now ?? clock.now() {
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final inThePast = date.isBefore(now);

    return Timeago(
      date: date,
      clock: now,
      allowFromNow: true,
      locale: inThePast ? "poke-en-past" : "poke-en-future",
      builder: _build,
    );
  }

  Widget _build(BuildContext context, String timeAgo) {
    final s = format == null ? timeAgo : format!(timeAgo);
    return PokeText.withStyle(s, textStyle);
  }
}

abstract class PokeEnMessages implements LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';

  @override
  String wordSeparator() => ' ';
}

class PokeEnPastMessages extends PokeEnMessages {
  @override
  String lessThanOneMinute(int seconds) => 'a moment ago';
  @override
  String aboutAMinute(int minutes) => 'a minute ago';
  @override
  String minutes(int minutes) => '$minutes minutes ago';
  @override
  String aboutAnHour(int minutes) => 'about an hour ago';
  @override
  String hours(int hours) => hours == 24 ? aDay(hours) : '$hours hours ago';
  @override
  String aDay(int hours) => 'yesterday';
  @override
  String days(int days) => '$days days ago';
  @override
  String aboutAMonth(int days) => 'about a month ago';
  @override
  String months(int months) => '$months months ago';
  @override
  String aboutAYear(int year) => 'about a year ago';
  @override
  String years(int years) => '$years years ago';
}

class PokeEnFutureMessages extends PokeEnMessages {
  @override
  String lessThanOneMinute(int seconds) => 'In a moment';
  @override
  String aboutAMinute(int minutes) => 'In a minute';
  @override
  String minutes(int minutes) => 'In $minutes minutes';
  @override
  String aboutAnHour(int minutes) => 'In about an hour';
  @override
  String hours(int hours) => hours == 24 ? aDay(hours) : 'In $hours hours';
  @override
  String aDay(int hours) => 'tomorrow';
  @override
  String days(int days) => 'In $days days';
  @override
  String aboutAMonth(int days) => 'In about a month';
  @override
  String months(int months) => 'In $months months';
  @override
  String aboutAYear(int year) => 'In about a year';
  @override
  String years(int years) => 'In $years years';
}
