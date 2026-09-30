import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/course.dart';

class CourseRepository {
  CourseRepository(this._db);

  final AppDatabase _db;

  Future<List<Course>> getAll({bool includeHidden = true}) async {
    final rows = await _db.db.query(
      'courses',
      where: includeHidden ? null : 'hidden = 0',
      orderBy: 'name',
    );
    return rows.map(Course.fromRow).toList();
  }

  Future<Course?> getById(int id) async {
    final rows = await _db.db.query('courses', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Course.fromRow(rows.first);
  }

  /// Upserts API courses, preserving user-editable fields (nickname, hidden).
  Future<void> upsertFromApi(List<Course> courses) async {
    final batch = _db.db.batch();
    for (final course in courses) {
      batch.rawInsert(
        '''
        INSERT INTO courses(id, name, course_code, hidden, term_name, term_end_at)
        VALUES(?, ?, ?, 0, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          course_code = excluded.course_code,
          term_name = excluded.term_name,
          term_end_at = excluded.term_end_at
        ''',
        [
          course.id,
          course.name,
          course.courseCode,
          course.termName,
          course.termEndAt?.toIso8601String(),
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Courses belonging to the academic term running right now — what the
  /// timetable and "next class" views should be built from.
  Future<List<Course>> getCurrent({bool includeHidden = true}) async {
    final all = await getAll(includeHidden: includeHidden);
    return all.where((c) => c.isCurrentTerm).toList();
  }

  Future<void> setNickname(int courseId, String? nickname) async {
    await _db.db.update(
      'courses',
      {'nickname': (nickname == null || nickname.isEmpty) ? null : nickname},
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  Future<void> setHidden(int courseId, bool hidden) async {
    await _db.db.update(
      'courses',
      {'hidden': hidden ? 1 : 0},
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  Database get raw => _db.db;
}
