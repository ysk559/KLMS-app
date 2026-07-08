import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static Future<AppDatabase> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'klms_app.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE courses(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            course_code TEXT,
            nickname TEXT,
            hidden INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY,
            course_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            type TEXT NOT NULL DEFAULT 'assignment',
            due_at TEXT,
            html_url TEXT,
            points_possible REAL,
            lms_completed INTEGER NOT NULL DEFAULT 0,
            user_completed INTEGER NOT NULL DEFAULT 0,
            conflict_notified INTEGER NOT NULL DEFAULT 0,
            description TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE announcements(
            id INTEGER PRIMARY KEY,
            course_id INTEGER,
            title TEXT NOT NULL,
            message TEXT,
            url TEXT,
            posted_at TEXT,
            is_read INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_tasks_course ON tasks(course_id)');
        await db.execute('CREATE INDEX idx_tasks_due ON tasks(due_at)');
        await db
            .execute('CREATE INDEX idx_ann_posted ON announcements(posted_at)');
      },
    );
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();
}
