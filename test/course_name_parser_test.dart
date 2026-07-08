import 'package:flutter_test/flutter_test.dart';
import 'package:klms_app/core/utils/course_name_parser.dart';

void main() {
  group('CourseNameParser', () {
    test('parses the canonical KLMS example', () {
      final p = CourseNameParser.parse(
          '3-12春［月2月3月4］今井倫太 情報工学実験第 1B［矢上12-204］');
      expect(p.courseNumber, '3-12');
      expect(p.term, '春');
      expect(p.teacher, '今井倫太');
      expect(p.displayName, '情報工学実験第 1B');
      expect(p.room, '矢上12-204');
      expect(p.slots, const [
        CourseSlot(weekday: DateTime.monday, period: 2),
        CourseSlot(weekday: DateTime.monday, period: 3),
        CourseSlot(weekday: DateTime.monday, period: 4),
      ]);
    });

    test('parses a single-slot course', () {
      final p = CourseNameParser.parse('1-1秋［水3］山田太郎 微分積分［日吉J11］');
      expect(p.term, '秋');
      expect(p.slots, const [CourseSlot(weekday: DateTime.wednesday, period: 3)]);
      expect(p.displayName, '微分積分');
      expect(p.room, '日吉J11');
    });

    test('parses slots on different weekdays', () {
      final p = CourseNameParser.parse('2-5通年［火1金2］教員名 体育実技A［綱島）］');
      expect(p.term, '通年');
      expect(p.slots, const [
        CourseSlot(weekday: DateTime.tuesday, period: 1),
        CourseSlot(weekday: DateTime.friday, period: 2),
      ]);
    });

    test('course without brackets has no schedule', () {
      final p = CourseNameParser.parse('教職課程ガイダンス2026');
      expect(p.hasSchedule, isFalse);
      expect(p.displayName, '教職課程ガイダンス2026');
    });

    test('course without room bracket', () {
      final p = CourseNameParser.parse('9-99春［木5］担当者 特別講義');
      expect(p.room, isNull);
      expect(p.displayName, '特別講義');
      expect(p.slots, const [CourseSlot(weekday: DateTime.thursday, period: 5)]);
    });

    test('half-width brackets are tolerated', () {
      final p = CourseNameParser.parse('3-12春[月2]今井倫太 情報工学実験[矢上12-204]');
      expect(p.slots, const [CourseSlot(weekday: DateTime.monday, period: 2)]);
      expect(p.room, '矢上12-204');
    });

    test('full-width space separates teacher and title', () {
      final p = CourseNameParser.parse('1-2春［金4］教師名　科目名X［教室1］');
      expect(p.teacher, '教師名');
      expect(p.displayName, '科目名X');
    });

    test('non-schedule bracket content is not treated as slots', () {
      final p = CourseNameParser.parse('集中講義［未定］特別演習');
      expect(p.hasSchedule, isFalse);
    });
  });
}
