import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static const String databaseName = 'classduck.db';
  static const int databaseVersion = 4;

  static const String tableCourseTable = 'course_table';
  static const String tableCourse = 'course';
  static const String tableTodo = 'todo_item';
  static const String tableSetting = 'app_setting';

  static const String createCourseTableSql = '''
CREATE TABLE course_table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  semester_start_monday TEXT,
  class_time_list_json TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''';

  static const String createCourseSql = '''
CREATE TABLE course (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  classroom TEXT,
  class_number TEXT,
  teacher TEXT,
  test_time TEXT,
  test_location TEXT,
  info_link TEXT,
  info TEXT,
  weeks_json TEXT NOT NULL,
  week_time INTEGER NOT NULL,
  start_time INTEGER NOT NULL,
  time_count INTEGER NOT NULL,
  import_type INTEGER NOT NULL,
  color_hex TEXT,
  course_id INTEGER,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(table_id) REFERENCES course_table(id) ON DELETE CASCADE
);
''';

  static const String createTodoSql = '''
CREATE TABLE todo_item (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  task_type TEXT NOT NULL,
  table_id INTEGER,
  course_name TEXT,
  due_at TEXT NOT NULL,
  is_completed INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''';

  static const String createSettingSql = '''
CREATE TABLE IF NOT EXISTS app_setting (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
''';

  static final Map<String, String> _webSettings = <String, String>{};

  Future<Database> open() async {
    final String dbPath = await getDatabasesPath();
    final String filePath = p.join(dbPath, databaseName);

    return openDatabase(
      filePath,
      version: databaseVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await db.execute(createCourseTableSql);
        await db.execute(createCourseSql);
        await db.execute(createTodoSql);
        await db.execute(createSettingSql);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(createTodoSql);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE $tableTodo ADD COLUMN table_id INTEGER');
          final List<Map<String, Object?>> tables = await db.query(
            tableCourseTable,
            columns: const <String>['id'],
            orderBy: 'id DESC',
            limit: 1,
          );
          final int? fallbackTableId = tables.isNotEmpty ? tables.first['id'] as int? : null;
          if (fallbackTableId != null) {
            await db.update(
              tableTodo,
              <String, Object?>{'table_id': fallbackTableId},
              where: 'table_id IS NULL',
            );
          }
        }
        if (oldVersion < 4) {
          await db.execute(createSettingSql);
        }
      },
    );
  }

  Future<String?> getSetting(String key) async {
    if (kIsWeb) {
      return _webSettings[key];
    }
    final Database db = await open();
    final List<Map<String, Object?>> rows = await db.query(
      tableSetting,
      columns: const <String>['value'],
      where: 'key = ?',
      whereArgs: <Object>[key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    if (kIsWeb) {
      _webSettings[key] = value;
      return;
    }
    final Database db = await open();
    await db.insert(
      tableSetting,
      <String, Object?>{'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
