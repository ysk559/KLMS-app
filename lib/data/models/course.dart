import '../../core/utils/course_name_parser.dart';

class Course {
  Course({
    required this.id,
    required this.name,
    this.courseCode,
    this.nickname,
    this.hidden = false,
    this.termName,
    this.termEndAt,
  });

  final int id;

  /// Raw KLMS course name, e.g.
  /// `3-12春［月2月3月4］今井倫太 情報工学実験第 1B［矢上12-204］`.
  final String name;
  final String? courseCode;

  /// User-defined nickname, shown as `[nickname]` before task titles.
  final String? nickname;
  final bool hidden;

  /// Canvas enrollment term (e.g. `2026 秋学期`) and when it ends, when the
  /// LMS reports them.
  final String? termName;
  final DateTime? termEndAt;

  ParsedCourseName? _parsed;
  ParsedCourseName get parsed => _parsed ??= CourseNameParser.parse(name);

  /// Whether this course belongs to the academic term running right now.
  ///
  /// Canvas keeps last term's enrollments in `active` state for a while after
  /// the term ends, so "the API returned it" is not enough to put a course on
  /// the timetable. Canvas' own term end date wins when present; otherwise we
  /// fall back to the 春/秋 marker KLMS puts in the course name.
  ///
  /// Anything we cannot classify (通年, 夏/冬 intensives, unparsable names)
  /// counts as current — showing one course too many is better than hiding a
  /// real one.
  bool get isCurrentTerm => isCurrentTermAt(DateTime.now());

  bool isCurrentTermAt(DateTime now) {
    final end = termEndAt;
    if (end != null) return end.isAfter(now);
    final term = parsed.term;
    if (term != '春' && term != '秋') return true;
    return term == currentAcademicTerm(now);
  }

  /// Keio's academic calendar: 春学期 runs April–August, 秋学期 September–March.
  static String currentAcademicTerm(DateTime now) =>
      (now.month >= 4 && now.month <= 8) ? '春' : '秋';

  /// Whether something attached to [courseId] (a task, a widget row) belongs
  /// to the term running now. A course we have no record of counts as current,
  /// on the same "never hide a real one" principle as [isCurrentTerm].
  static bool courseIsCurrentTerm(int courseId, Map<int, Course> byId) {
    final course = byId[courseId];
    return course == null || course.isCurrentTerm;
  }

  /// Short label to identify the course in lists: nickname if set,
  /// otherwise the parsed course title.
  String get shortLabel =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : parsed.displayName;

  Course copyWith({String? nickname, bool? hidden}) => Course(
        id: id,
        name: name,
        courseCode: courseCode,
        nickname: nickname ?? this.nickname,
        hidden: hidden ?? this.hidden,
        termName: termName,
        termEndAt: termEndAt,
      );

  factory Course.fromApi(Map<String, dynamic> json) {
    // Present when the request asks for `include[]=term`.
    final term = json['term'] as Map<String, dynamic>?;
    return Course(
      id: json['id'] as int,
      name: (json['name'] ?? json['course_code'] ?? '?') as String,
      courseCode: json['course_code'] as String?,
      termName: term?['name'] as String?,
      termEndAt: DateTime.tryParse(term?['end_at'] as String? ?? '')?.toLocal(),
    );
  }

  factory Course.fromRow(Map<String, dynamic> row) => Course(
        id: row['id'] as int,
        name: row['name'] as String,
        courseCode: row['course_code'] as String?,
        nickname: row['nickname'] as String?,
        hidden: (row['hidden'] as int? ?? 0) != 0,
        termName: row['term_name'] as String?,
        termEndAt: DateTime.tryParse(row['term_end_at'] as String? ?? ''),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'course_code': courseCode,
        'nickname': nickname,
        'hidden': hidden ? 1 : 0,
        'term_name': termName,
        'term_end_at': termEndAt?.toIso8601String(),
      };
}
