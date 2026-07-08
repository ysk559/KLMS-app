import '../db/app_database.dart';
import '../models/task_item.dart';

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  Future<List<TaskItem>> getAll() async {
    final rows = await _db.db.query(
      'tasks',
      orderBy: 'due_at IS NULL, due_at ASC',
    );
    return rows.map(TaskItem.fromRow).toList();
  }

  Future<List<TaskItem>> getIncomplete() async {
    final rows = await _db.db.query(
      'tasks',
      where: 'lms_completed = 0 AND user_completed = 0',
      orderBy: 'due_at IS NULL, due_at ASC',
    );
    return rows.map(TaskItem.fromRow).toList();
  }

  /// Tasks the user marked done that a fresh sync says are not done on the
  /// LMS, and that have not been notified about yet.
  Future<List<TaskItem>> getUnnotifiedConflicts() async {
    final rows = await _db.db.query(
      'tasks',
      where:
          'user_completed = 1 AND lms_completed = 0 AND conflict_notified = 0',
    );
    return rows.map(TaskItem.fromRow).toList();
  }

  /// Upserts tasks from the API, preserving user state
  /// (user_completed / conflict_notified).
  Future<void> upsertFromApi(List<TaskItem> tasks) async {
    final batch = _db.db.batch();
    for (final t in tasks) {
      batch.rawInsert(
        '''
        INSERT INTO tasks(id, course_id, title, type, due_at, html_url,
                          points_possible, lms_completed, description)
        VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          course_id = excluded.course_id,
          title = excluded.title,
          type = excluded.type,
          due_at = excluded.due_at,
          html_url = excluded.html_url,
          points_possible = excluded.points_possible,
          lms_completed = excluded.lms_completed,
          description = excluded.description,
          -- LMS caught up: clear the conflict-notified flag so a future
          -- regression can be re-detected.
          conflict_notified = CASE WHEN excluded.lms_completed = 1
                                   THEN 0 ELSE conflict_notified END
        ''',
        [
          t.id,
          t.courseId,
          t.title,
          t.type,
          t.dueAt?.toIso8601String(),
          t.htmlUrl,
          t.pointsPossible,
          t.lmsCompleted ? 1 : 0,
          t.description,
        ],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> setUserCompleted(int taskId, bool completed) async {
    await _db.db.update(
      'tasks',
      {
        'user_completed': completed ? 1 : 0,
        // Re-arm conflict detection when the user toggles.
        'conflict_notified': 0,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> markConflictNotified(Iterable<int> taskIds) async {
    if (taskIds.isEmpty) return;
    final ids = taskIds.join(',');
    await _db.db
        .rawUpdate('UPDATE tasks SET conflict_notified = 1 WHERE id IN ($ids)');
  }

  /// Removes tasks that no longer exist on the LMS for a given course.
  Future<void> deleteMissing(int courseId, Set<int> keepIds) async {
    if (keepIds.isEmpty) {
      await _db.db
          .delete('tasks', where: 'course_id = ?', whereArgs: [courseId]);
      return;
    }
    final ids = keepIds.join(',');
    await _db.db.delete(
      'tasks',
      where: 'course_id = ? AND id NOT IN ($ids)',
      whereArgs: [courseId],
    );
  }
}
