import '../db/app_database.dart';
import '../models/announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository(this._db);

  final AppDatabase _db;

  Future<List<Announcement>> getRecent({int limit = 50}) async {
    final rows = await _db.db.query(
      'announcements',
      orderBy: 'posted_at DESC',
      limit: limit,
    );
    return rows.map(Announcement.fromRow).toList();
  }

  Future<List<Announcement>> getForCourse(int courseId) async {
    final rows = await _db.db.query(
      'announcements',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'posted_at DESC',
    );
    return rows.map(Announcement.fromRow).toList();
  }

  /// Inserts announcements, returning the ones that were new.
  Future<List<Announcement>> upsertFromApi(List<Announcement> items) async {
    if (items.isEmpty) return const [];
    final ids = items.map((e) => e.id).join(',');
    final existing = (await _db.db
            .rawQuery('SELECT id FROM announcements WHERE id IN ($ids)'))
        .map((r) => r['id'] as int)
        .toSet();

    final batch = _db.db.batch();
    for (final a in items) {
      batch.rawInsert(
        '''
        INSERT INTO announcements(id, course_id, title, message, url, posted_at)
        VALUES(?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          title = excluded.title,
          message = excluded.message,
          url = excluded.url,
          posted_at = excluded.posted_at
        ''',
        [
          a.id,
          a.courseId,
          a.title,
          a.message,
          a.url,
          a.postedAt?.toIso8601String(),
        ],
      );
    }
    await batch.commit(noResult: true);
    return items.where((a) => !existing.contains(a.id)).toList();
  }

  Future<void> markRead(int id) async {
    await _db.db.update('announcements', {'is_read': 1},
        where: 'id = ?', whereArgs: [id]);
  }
}
