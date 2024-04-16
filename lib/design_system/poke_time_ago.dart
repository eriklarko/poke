import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class PokeTimeAgo extends StatelessWidget {
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
  }) : now = now ?? clock.now();

  @override
  Widget build(BuildContext context) {
    return Timeago(
      date: date,
      clock: now,
      allowFromNow: true,
      builder: (BuildContext context, String timeAgoString) {
        final s = format == null ? timeAgoString : format!(timeAgoString);
        return PokeText.withStyle(s, textStyle);
      },
    );
  }
}
