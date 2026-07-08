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
        INSERT INTO courses(id, name, course_code, hidden)
        VALUES(?, ?, ?, 0)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          course_code = excluded.course_code
        ''',
        [course.id, course.name, course.courseCode],
      );
    }
    await batch.commit(noResult: true);
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
