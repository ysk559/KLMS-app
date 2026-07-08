import 'package:intl/intl.dart';

import '../../data/models/course.dart';

/// `[course label]title` — the label is the nickname when set, otherwise
/// the parsed course title.
String decorateTaskTitle(String title, Course? course) {
  if (course == null) return title;
  final label = course.shortLabel;
  if (label.isEmpty) return title;
  return '[$label]$title';
}

String formatDateTimeShort(DateTime dt) =>
    DateFormat('M/d (E) HH:mm').format(dt.toLocal());

String formatTimeShort(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());
