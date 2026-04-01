import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/local/db_helper.dart';
import '../domain/course.dart';
import '../domain/course_table.dart';

/// 课程表数据仓库。
///
/// 设计上分成两条存储路径：
/// 1. 原生端：使用 sqflite / sqflite_common_ffi 落到 SQLite。
/// 2. Web 端：由于当前导入链路本身就是降级态，且 Web 端的数据库初始化
///    和 worker 资源管理更复杂，因此先用内存集合模拟最小可用数据层。
///
/// 这样可以保证课程表、待办、我的页面在 Web 调试下至少能启动，
/// 同时不影响 Windows/Android/iOS 的真实落库行为。
class ScheduleRepository {
  ScheduleRepository({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper();

  final DbHelper _dbHelper;
  static int _webTableIdSeed = 1;
  static int _webCourseIdSeed = 1;
  static final List<CourseTableEntity> _webTables = <CourseTableEntity>[];
  static final List<CourseEntity> _webCourses = <CourseEntity>[];

  /// 创建课表。Web 端写入内存，原生端写入 SQLite。
  Future<CourseTableEntity> createCourseTable({
    required String name,
    String? semesterStartMonday,
    List<Map<String, String>>? classTimeList,
  }) async {
    if (kIsWeb) {
      final String now = DateTime.now().toUtc().toIso8601String();
      final CourseTableEntity entity = CourseTableEntity(
        id: _webTableIdSeed++,
        name: name,
        semesterStartMonday: semesterStartMonday,
        classTimeListJson: classTimeList == null ? null : jsonEncode(classTimeList),
        createdAt: now,
        updatedAt: now,
      );
      _webTables.add(entity);
      return entity;
    }

    final Database db = await _dbHelper.open();
    final String now = DateTime.now().toUtc().toIso8601String();

    final CourseTableEntity entity = CourseTableEntity(
      name: name,
      semesterStartMonday: semesterStartMonday,
      classTimeListJson: classTimeList == null ? null : jsonEncode(classTimeList),
      createdAt: now,
      updatedAt: now,
    );

    final int id = await db.insert(
      DbHelper.tableCourseTable,
      entity.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return CourseTableEntity(
      id: id,
      name: entity.name,
      semesterStartMonday: entity.semesterStartMonday,
      classTimeListJson: entity.classTimeListJson,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// 获取全部课表。Web 端为空时会自动补一张默认课表，避免页面空引用。
  Future<List<CourseTableEntity>> getCourseTables() async {
    if (kIsWeb) {
      if (_webTables.isEmpty) {
        final String now = DateTime.now().toUtc().toIso8601String();
        _webTables.add(
          CourseTableEntity(
            id: _webTableIdSeed++,
            name: '我的课表',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      return _webTables.reversed.toList(growable: false);
    }

    final Database db = await _dbHelper.open();

    final List<Map<String, Object?>> rows = await db.query(
      DbHelper.tableCourseTable,
      orderBy: 'id DESC',
    );

    return rows.map(CourseTableEntity.fromMap).toList(growable: false);
  }

  /// 批量写入课程。
  Future<void> addCourses({
    required int tableId,
    required List<CourseEntity> courses,
  }) async {
    if (kIsWeb) {
      for (final CourseEntity course in courses) {
        _webCourses.add(
          CourseEntity(
            id: _webCourseIdSeed++,
            tableId: tableId,
            name: course.name,
            classroom: course.classroom,
            classNumber: course.classNumber,
            teacher: course.teacher,
            testTime: course.testTime,
            testLocation: course.testLocation,
            infoLink: course.infoLink,
            info: course.info,
            weeksJson: course.weeksJson,
            weekTime: course.weekTime,
            startTime: course.startTime,
            timeCount: course.timeCount,
            importType: course.importType,
            colorHex: course.colorHex,
            courseId: course.courseId,
            createdAt: course.createdAt,
            updatedAt: course.updatedAt,
          ),
        );
      }
      return;
    }

    final Database db = await _dbHelper.open();

    await db.transaction((Transaction txn) async {
      for (final CourseEntity course in courses) {
        await txn.insert(
          DbHelper.tableCourse,
          course.toMap()
            ..remove('id')
            ..['table_id'] = tableId,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<List<CourseEntity>> getCoursesByTableId(int tableId) async {
    if (kIsWeb) {
      final List<CourseEntity> rows = _webCourses
          .where((CourseEntity item) => item.tableId == tableId)
          .toList(growable: false);
      rows.sort((CourseEntity a, CourseEntity b) {
        if (a.weekTime != b.weekTime) {
          return a.weekTime.compareTo(b.weekTime);
        }
        return a.startTime.compareTo(b.startTime);
      });
      return rows;
    }

    final Database db = await _dbHelper.open();

    final List<Map<String, Object?>> rows = await db.query(
      DbHelper.tableCourse,
      where: 'table_id = ?',
      whereArgs: <Object>[tableId],
      orderBy: 'week_time ASC, start_time ASC',
    );

    return rows.map(CourseEntity.fromMap).toList(growable: false);
  }

  Future<void> deleteCourseTable(int tableId) async {
    if (kIsWeb) {
      _webTables.removeWhere((CourseTableEntity item) => item.id == tableId);
      _webCourses.removeWhere((CourseEntity item) => item.tableId == tableId);
      return;
    }

    final Database db = await _dbHelper.open();
    await db.delete(
      DbHelper.tableCourseTable,
      where: 'id = ?',
      whereArgs: <Object>[tableId],
    );
  }

  /// 清空全部课表及其课程。
  Future<void> clearAllCourseTables() async {
    if (kIsWeb) {
      _webTables.clear();
      _webCourses.clear();
      return;
    }

    final Database db = await _dbHelper.open();
    await db.delete(DbHelper.tableCourseTable);
  }

  /// 重命名课表。
  Future<void> renameCourseTable({
    required int tableId,
    required String newName,
  }) async {
    if (kIsWeb) {
      final int index =
          _webTables.indexWhere((CourseTableEntity item) => item.id == tableId);
      if (index < 0) return;
      final CourseTableEntity current = _webTables[index];
      _webTables[index] = CourseTableEntity(
        id: current.id,
        name: newName,
        semesterStartMonday: current.semesterStartMonday,
        classTimeListJson: current.classTimeListJson,
        createdAt: current.createdAt,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      return;
    }

    final Database db = await _dbHelper.open();
    await db.update(
      DbHelper.tableCourseTable,
      <String, Object?>{
        'name': newName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[tableId],
    );
  }

  Future<void> updateCourseTableConfig({
    required int tableId,
    String? semesterStartMonday,
    String? classTimeListJson,
  }) async {
    if (kIsWeb) {
      final int index = _webTables.indexWhere((CourseTableEntity item) => item.id == tableId);
      if (index < 0) {
        return;
      }
      final CourseTableEntity current = _webTables[index];
      _webTables[index] = CourseTableEntity(
        id: current.id,
        name: current.name,
        semesterStartMonday: semesterStartMonday ?? current.semesterStartMonday,
        classTimeListJson: classTimeListJson ?? current.classTimeListJson,
        createdAt: current.createdAt,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      return;
    }

    final Database db = await _dbHelper.open();
    await db.update(
      DbHelper.tableCourseTable,
      <String, Object?>{
        'semester_start_monday': semesterStartMonday,
        'class_time_list_json': classTimeListJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[tableId],
    );
  }

  Future<int> getTotalCourseCount() async {
    if (kIsWeb) {
      return _webCourses.length;
    }

    final Database db = await _dbHelper.open();
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DbHelper.tableCourse}',
    );
    final Object? count = rows.first['count'];
    return (count as int?) ?? 0;
  }

  Future<int> getDoneCourseCount({DateTime? now}) async {
    final DateTime localNow = now ?? DateTime.now();
    final int weekday = localNow.weekday;
    final int currentPeriod = _guessCurrentPeriod(localNow);

    int done = 0;
    final List<CourseEntity> source;
    if (kIsWeb) {
      source = _webCourses;
    } else {
      final Database db = await _dbHelper.open();
      final List<Map<String, Object?>> rows = await db.query(DbHelper.tableCourse);
      source = rows.map(CourseEntity.fromMap).toList(growable: false);
    }
    for (final CourseEntity course in source) {
      final int endPeriod = course.startTime + course.timeCount;

      if (course.weekTime < weekday) {
        done++;
      } else if (course.weekTime == weekday && endPeriod < currentPeriod) {
        done++;
      }
    }

    return done;
  }

  int _guessCurrentPeriod(DateTime now) {
    final int hm = now.hour * 100 + now.minute;

    if (hm < 800) return 0;
    if (hm <= 845) return 1;
    if (hm <= 940) return 2;
    if (hm <= 1045) return 3;
    if (hm <= 1145) return 4;
    if (hm <= 1445) return 5;
    if (hm <= 1545) return 6;
    if (hm <= 1645) return 7;
    if (hm <= 1745) return 8;
    return 99;
  }
}
