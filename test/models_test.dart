import 'package:flutter_test/flutter_test.dart';
import 'package:klms_app/core/utils/formatting.dart';
import 'package:klms_app/data/models/course.dart';
import 'package:klms_app/data/models/task_item.dart';
import 'package:klms_app/data/settings/app_settings.dart';

void main() {
  group('TaskItem.fromAssignmentApi', () {
    test('submitted assignment is LMS-completed', () {
      final t = TaskItem.fromAssignmentApi({
        'id': 1,
        'course_id': 10,
        'name': 'レポート1',
        'due_at': '2026-07-10T14:59:59Z',
        'html_url': 'https://lms.keio.jp/courses/10/assignments/1',
        'points_possible': 100,
        'submission': {
          'workflow_state': 'submitted',
          'submitted_at': '2026-07-01T00:00:00Z',
        },
      });
      expect(t.lmsCompleted, isTrue);
      expect(t.isCompleted, isTrue);
      expect(t.dueAt, DateTime.utc(2026, 7, 10, 14, 59, 59));
    });

    test('unsubmitted assignment is not completed', () {
      final t = TaskItem.fromAssignmentApi({
        'id': 2,
        'course_id': 10,
        'name': 'レポート2',
        'submission': {'workflow_state': 'unsubmitted'},
      });
      expect(t.lmsCompleted, isFalse);
      expect(t.isCompleted, isFalse);
    });

    test('user completion and conflict flags', () {
      const t = TaskItem(
          id: 3, courseId: 10, title: 'x', userCompleted: true);
      expect(t.isCompleted, isTrue);
      expect(t.hasConflict, isTrue);
      expect(t.copyWith(lmsCompleted: true).hasConflict, isFalse);
    });
  });

  group('decorateTaskTitle', () {
    final course = Course(
        id: 1,
        name: '3-12春［月2月3月4］今井倫太 情報工学実験第 1B［矢上12-204］',
        nickname: 'Jexp');

    test('prepends [nickname]', () {
      expect(decorateTaskTitle('課題1', course), '[Jexp]課題1');
    });

    test('no nickname falls back to the parsed course title', () {
      expect(decorateTaskTitle('課題1', course.copyWith(nickname: '')),
          '[情報工学実験第 1B]課題1');
      expect(decorateTaskTitle('課題1', null), '課題1');
    });
  });

  group('AppSettings serialization', () {
    test('round-trips', () {
      const settings = AppSettings(
        reminderHours: 3,
        reminderMinutes: 30,
        excludeWords: ['再提出'],
        excludedCourseIds: {5, 7},
        periodsPerDay: 7,
        backgroundSyncMinutes: 60,
      );
      final restored = AppSettings.fromJsonString(settings.toJsonString());
      expect(restored.reminderHours, 3);
      expect(restored.reminderMinutes, 30);
      expect(restored.excludeWords, ['再提出']);
      expect(restored.excludedCourseIds, {5, 7});
      expect(restored.periodsPerDay, 7);
      expect(restored.backgroundSyncMinutes, 60);
      expect(restored.reminderOffset, const Duration(hours: 3, minutes: 30));
    });

    test('default period times follow the Keio schedule', () {
      expect(kDefaultPeriodTimes.first.startLabel, '09:00');
      expect(kDefaultPeriodTimes.first.endLabel, '10:30');
      expect(kDefaultPeriodTimes.length, 6);
    });
  });
}
