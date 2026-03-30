import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/local/db_helper.dart';
import '../domain/todo_item.dart';

class TodoRepository {
  TodoRepository({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper();

  final DbHelper _dbHelper;
  static int _webIdSeed = 1;
  static final List<TodoItem> _webItems = <TodoItem>[];
  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  static void _notifyDataChanged() {
    dataVersion.value = dataVersion.value + 1;
  }

  String _normalizeLinkedCourseName(String? raw) {
    if (raw == null) {
      return '';
    }
    String normalized = raw.trim().toLowerCase();
    // 历史数据可能带有课程补充后缀（如“课程名(周一1-2节)”），删除时按主名联动。
    normalized = normalized.replaceAll(RegExp(r'[（(].*[）)]$'), '');
    normalized = normalized.replaceAll(RegExp(r'[\u3000\s]+'), '');
    return normalized;
  }

  Future<TodoItem> addTodo({
    required String title,
    required String taskType,
    required int tableId,
    String? courseName,
    required DateTime dueAt,
  }) async {
    if (kIsWeb) {
      final String now = DateTime.now().toUtc().toIso8601String();
      final TodoItem item = TodoItem(
        id: _webIdSeed++,
        title: title,
        taskType: taskType,
        tableId: tableId,
        courseName: courseName,
        dueAt: dueAt.toUtc().toIso8601String(),
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      _webItems.add(item);
      _notifyDataChanged();
      return item;
    }

    final Database db = await _dbHelper.open();
    final String now = DateTime.now().toUtc().toIso8601String();

    final TodoItem item = TodoItem(
      title: title,
      taskType: taskType,
      tableId: tableId,
      courseName: courseName,
      dueAt: dueAt.toUtc().toIso8601String(),
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    final int id = await db.insert(
      DbHelper.tableTodo,
      item.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    _notifyDataChanged();

    return TodoItem(
      id: id,
      title: item.title,
      taskType: item.taskType,
      tableId: item.tableId,
      courseName: item.courseName,
      dueAt: item.dueAt,
      isCompleted: item.isCompleted,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  Future<List<TodoItem>> getTodos({required bool completed, int? tableId}) async {
    if (kIsWeb) {
      final List<TodoItem> rows = _webItems
          .where((TodoItem item) =>
              item.isCompleted == completed && (tableId == null || item.tableId == tableId))
          .toList(growable: false);
      rows.sort((TodoItem a, TodoItem b) => a.dueAt.compareTo(b.dueAt));
      return rows;
    }

    final Database db = await _dbHelper.open();

    final String where = tableId == null ? 'is_completed = ?' : 'is_completed = ? AND table_id = ?';
    final List<Object> whereArgs = tableId == null
        ? <Object>[completed ? 1 : 0]
        : <Object>[completed ? 1 : 0, tableId];

    final List<Map<String, Object?>> rows = await db.query(
      DbHelper.tableTodo,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'due_at ASC',
    );

    return rows.map(TodoItem.fromMap).toList(growable: false);
  }

  Future<List<TodoItem>> getTodosByCourseName(String courseName, {int? tableId}) async {
    if (kIsWeb) {
      final List<TodoItem> rows = _webItems
          .where((TodoItem item) =>
              item.courseName == courseName && (tableId == null || item.tableId == tableId))
          .toList(growable: false);
      rows.sort((TodoItem a, TodoItem b) => a.dueAt.compareTo(b.dueAt));
      return rows;
    }

    final Database db = await _dbHelper.open();

    final String where = tableId == null ? 'course_name = ?' : 'course_name = ? AND table_id = ?';
    final List<Object> whereArgs = tableId == null ? <Object>[courseName] : <Object>[courseName, tableId];

    final List<Map<String, Object?>> rows = await db.query(
      DbHelper.tableTodo,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'due_at ASC',
    );

    return rows.map(TodoItem.fromMap).toList(growable: false);
  }

  Future<void> renameCourseName({
    required String from,
    required String to,
    int? tableId,
  }) async {
    final String source = from.trim();
    final String target = to.trim();
    if (source.isEmpty || target.isEmpty || source == target) {
      return;
    }

    final String sourceKey = _normalizeLinkedCourseName(source);

    if (kIsWeb) {
      bool changed = false;
      for (int i = 0; i < _webItems.length; i++) {
        final TodoItem item = _webItems[i];
        if (tableId != null && item.tableId != tableId) {
          continue;
        }
        if (_normalizeLinkedCourseName(item.courseName) != sourceKey) {
          continue;
        }
        changed = true;
        _webItems[i] = TodoItem(
          id: item.id,
          title: item.title,
          taskType: item.taskType,
          tableId: item.tableId,
          courseName: target,
          dueAt: item.dueAt,
          isCompleted: item.isCompleted,
          createdAt: item.createdAt,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
      }
      if (changed) {
        _notifyDataChanged();
      }
      return;
    }

    final Database db = await _dbHelper.open();

    final List<Map<String, Object?>> rows = await db.query(
      DbHelper.tableTodo,
      columns: const <String>['id', 'course_name', 'table_id'],
      where: tableId == null ? 'course_name IS NOT NULL' : 'course_name IS NOT NULL AND table_id = ?',
      whereArgs: tableId == null ? null : <Object>[tableId],
    );

    final String now = DateTime.now().toUtc().toIso8601String();
    final Batch batch = db.batch();
    bool changed = false;
    for (final Map<String, Object?> row in rows) {
      final int? id = row['id'] as int?;
      if (id == null) {
        continue;
      }
      final String key = _normalizeLinkedCourseName(row['course_name'] as String?);
      if (key != sourceKey) {
        continue;
      }
      changed = true;
      batch.update(
        DbHelper.tableTodo,
        <String, Object?>{
          'course_name': target,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
    }
    await batch.commit(noResult: true);
    if (changed) {
      _notifyDataChanged();
    }
  }

  Future<void> updateCompleted({
    required int id,
    required bool isCompleted,
  }) async {
    if (kIsWeb) {
      final int index = _webItems.indexWhere((TodoItem item) => item.id == id);
      if (index < 0) {
        return;
      }
      final TodoItem current = _webItems[index];
      _webItems[index] = TodoItem(
        id: current.id,
        title: current.title,
        taskType: current.taskType,
        tableId: current.tableId,
        courseName: current.courseName,
        dueAt: current.dueAt,
        isCompleted: isCompleted,
        createdAt: current.createdAt,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      _notifyDataChanged();
      return;
    }

    final Database db = await _dbHelper.open();
    await db.update(
      DbHelper.tableTodo,
      <String, Object?>{
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    _notifyDataChanged();
  }

  Future<void> deleteTodo(int id) async {
    if (kIsWeb) {
      final int before = _webItems.length;
      _webItems.removeWhere((TodoItem item) => item.id == id);
      if (_webItems.length != before) {
        _notifyDataChanged();
      }
      return;
    }

    final Database db = await _dbHelper.open();
    final int deleted = await db.delete(
      DbHelper.tableTodo,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
    if (deleted > 0) {
      _notifyDataChanged();
    }
  }

  Future<void> deleteTodosByTaskType(String taskType, {int? tableId}) async {
    if (kIsWeb) {
      final int before = _webItems.length;
      _webItems.removeWhere((TodoItem item) =>
          item.taskType == taskType && (tableId == null || item.tableId == tableId));
      if (_webItems.length != before) {
        _notifyDataChanged();
      }
      return;
    }

    final Database db = await _dbHelper.open();
    final String where = tableId == null ? 'task_type = ?' : 'task_type = ? AND table_id = ?';
    final List<Object> whereArgs = tableId == null ? <Object>[taskType] : <Object>[taskType, tableId];
    final int deleted = await db.delete(
      DbHelper.tableTodo,
      where: where,
      whereArgs: whereArgs,
    );
    if (deleted > 0) {
      _notifyDataChanged();
    }
  }

  Future<int> deleteTodosByCourseName(String courseName, {int? tableId}) async {
    final String sourceKey = _normalizeLinkedCourseName(courseName);
    if (sourceKey.isEmpty) {
      return 0;
    }

    if (kIsWeb) {
      final int before = _webItems.length;
      _webItems.removeWhere(
        (TodoItem item) =>
            _normalizeLinkedCourseName(item.courseName) == sourceKey &&
            (tableId == null || item.tableId == tableId),
      );
      final int removed = before - _webItems.length;
      if (removed > 0) {
        _notifyDataChanged();
      }
      return removed;
    }

    final Database db = await _dbHelper.open();
    final List<Map<String, Object?>> rows = await db.query(
      DbHelper.tableTodo,
      columns: const <String>['id', 'course_name', 'table_id'],
      where: tableId == null ? 'course_name IS NOT NULL' : 'course_name IS NOT NULL AND table_id = ?',
      whereArgs: tableId == null ? null : <Object>[tableId],
    );

    final List<int> matchedIds = rows
        .where((Map<String, Object?> row) {
          final String key = _normalizeLinkedCourseName(row['course_name'] as String?);
          return key == sourceKey;
        })
        .map((Map<String, Object?> row) => row['id'] as int?)
        .whereType<int>()
        .toList(growable: false);

    if (matchedIds.isEmpty) {
      return 0;
    }

    final Batch batch = db.batch();
    for (final int id in matchedIds) {
      batch.delete(
        DbHelper.tableTodo,
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
    }
    await batch.commit(noResult: true);
    _notifyDataChanged();
    return matchedIds.length;
  }
}
