import 'package:intl/intl.dart';

final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

String formatDate(DateTime dt) {
  return formatter.format(dt);
}
