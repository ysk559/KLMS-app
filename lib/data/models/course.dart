import '../../core/utils/course_name_parser.dart';

class Course {
  Course({
    required this.id,
    required this.name,
    this.courseCode,
    this.nickname,
    this.hidden = false,
  });

  final int id;

  /// Raw KLMS course name, e.g.
  /// `3-12春［月2月3月4］今井倫太 情報工学実験第 1B［矢上12-204］`.
  final String name;
  final String? courseCode;

  /// User-defined nickname, shown as `[nickname]` before task titles.
  final String? nickname;
  final bool hidden;

  ParsedCourseName? _parsed;
  ParsedCourseName get parsed => _parsed ??= CourseNameParser.parse(name);

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
      );

  factory Course.fromApi(Map<String, dynamic> json) => Course(
        id: json['id'] as int,
        name: (json['name'] ?? json['course_code'] ?? '?') as String,
        courseCode: json['course_code'] as String?,
      );

  factory Course.fromRow(Map<String, dynamic> row) => Course(
        id: row['id'] as int,
        name: row['name'] as String,
        courseCode: row['course_code'] as String?,
        nickname: row['nickname'] as String?,
        hidden: (row['hidden'] as int? ?? 0) != 0,
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'course_code': courseCode,
        'nickname': nickname,
        'hidden': hidden ? 1 : 0,
      };
}
