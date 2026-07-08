/// Parser for KLMS course names.
///
/// KLMS course names follow the pattern
/// `[course number][term]［[day+period]...］[teacher] [course name]［[room]］`
/// e.g. `3-12春［月2月3月4］今井倫太 情報工学実験第 1B［矢上12-204］`.
/// Both full-width `［］` and half-width `[]` brackets are tolerated.
library;

/// One weekday/period cell occupied by a course.
class CourseSlot {
  const CourseSlot({required this.weekday, required this.period});

  /// 1 = Monday ... 7 = Sunday (same as [DateTime.monday] etc.)
  final int weekday;

  /// 1-based class period.
  final int period;

  @override
  bool operator ==(Object other) =>
      other is CourseSlot && other.weekday == weekday && other.period == period;

  @override
  int get hashCode => Object.hash(weekday, period);

  @override
  String toString() => 'CourseSlot(weekday: $weekday, period: $period)';
}

class ParsedCourseName {
  const ParsedCourseName({
    required this.raw,
    required this.displayName,
    this.courseNumber,
    this.term,
    this.teacher,
    this.room,
    this.slots = const [],
  });

  final String raw;

  /// Human-friendly course title (without number/term/slots/teacher/room).
  final String displayName;
  final String? courseNumber;
  final String? term;
  final String? teacher;
  final String? room;
  final List<CourseSlot> slots;

  bool get hasSchedule => slots.isNotEmpty;
}

class CourseNameParser {
  CourseNameParser._();

  static const Map<String, int> _weekdayMap = {
    '月': DateTime.monday,
    '火': DateTime.tuesday,
    '水': DateTime.wednesday,
    '木': DateTime.thursday,
    '金': DateTime.friday,
    '土': DateTime.saturday,
    '日': DateTime.sunday,
  };

  static final RegExp _bracketGroup = RegExp(r'[［\[]([^］\]]*)[］\]]');
  static final RegExp _slotPattern = RegExp(r'(月|火|水|木|金|土|日)(\d+)');
  static final RegExp _termPattern = RegExp(r'(春|秋|夏|冬|通年)$');

  static ParsedCourseName parse(String raw) {
    final name = raw.trim();
    final brackets = _bracketGroup.allMatches(name).toList();

    if (brackets.isEmpty) {
      return ParsedCourseName(raw: raw, displayName: name);
    }

    // First bracket group: day/period slots. Last group (if distinct): room.
    final slotMatch = brackets.first;
    final slots = _parseSlots(slotMatch.group(1)!);

    String? room;
    var tailEnd = name.length;
    if (brackets.length >= 2 && slots.isNotEmpty) {
      final roomMatch = brackets.last;
      final roomText = roomMatch.group(1)!.trim();
      if (roomText.isNotEmpty) room = roomText;
      tailEnd = roomMatch.start;
    }

    if (slots.isEmpty) {
      // The first bracket group was not a schedule (e.g. intensive course).
      return ParsedCourseName(raw: raw, displayName: name, room: room);
    }

    // Prefix before the slot bracket: course number + term.
    final prefix = name.substring(0, slotMatch.start).trim();
    String? courseNumber;
    String? term;
    if (prefix.isNotEmpty) {
      final termMatch = _termPattern.firstMatch(prefix);
      if (termMatch != null) {
        term = termMatch.group(1);
        final num = prefix.substring(0, termMatch.start).trim();
        if (num.isNotEmpty) courseNumber = num;
      } else {
        courseNumber = prefix;
      }
    }

    // Tail after the slot bracket up to the room bracket:
    // `teacher name` + ` ` + `course title` (title itself may contain spaces).
    final tail = name.substring(slotMatch.end, tailEnd).trim();
    String? teacher;
    String displayName = tail;
    final spaceIndex = tail.indexOf(RegExp(r'[\s　]'));
    if (spaceIndex > 0) {
      teacher = tail.substring(0, spaceIndex);
      displayName = tail.substring(spaceIndex + 1).trim();
    }
    if (displayName.isEmpty) {
      displayName = tail.isEmpty ? name : tail;
      teacher = spaceIndex > 0 ? teacher : null;
    }

    return ParsedCourseName(
      raw: raw,
      displayName: displayName,
      courseNumber: courseNumber,
      term: term,
      teacher: teacher,
      room: room,
      slots: slots,
    );
  }

  static List<CourseSlot> _parseSlots(String text) {
    return _slotPattern
        .allMatches(text)
        .map((m) => CourseSlot(
              weekday: _weekdayMap[m.group(1)!]!,
              period: int.parse(m.group(2)!),
            ))
        .toList();
  }
}
