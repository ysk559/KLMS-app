import 'package:intl/intl.dart';

import '../../data/models/course.dart';

/// `[nickname]title` if the course has a nickname, otherwise just the title.
String decorateTaskTitle(String title, Course? course) {
  final nickname = course?.nickname;
  if (nickname == null || nickname.isEmpty) return title;
  return '[$nickname]$title';
}

String formatDateTimeShort(DateTime dt) =>
    DateFormat('M/d (E) HH:mm').format(dt.toLocal());

String formatTimeShort(DateTime dt) => DateFormat('HH:mm').format(dt.toLocal());
