import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/local/db_helper.dart';
import '../domain/todo_item.dart';

class TodoRepository {
  TodoRepository({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper();

  final DbHelper _dbHelper;
  static int _webIdSeed = 1;
  static final List<TodoItem> _webItems = <TodoItem>[];

  Future<TodoItem> addTodo({
    required String title,
    required String taskType,
    String? courseName,
    required DateTime dueAt,
  }) async {
    if (kIsWeb) {
      final String now = DateTime.now().toUtc().toIso8601String();
      final TodoItem item = TodoItem(
        id: _webIdSeed++,
        title: title,
        taskType: taskType,
        courseName: courseName,
        dueAt: dueAt.toUtc().toIso8601String(),
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      _webItems.add(item);
      return item;
    }

    final Database db = await _dbHelper.open();
    final String now = DateTime.now().toUtc().toIso8601String();

    final TodoItem item = TodoItem(
      title: title,
      taskType: taskType,
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

    return TodoItem(
      id: id,
      title: item.title,
      taskType: item.taskType,
      courseName: item.courseName,
      dueAt: item.dueAt,
      isCompleted: item.isCompleted,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  Future<List<TodoItem>> getTodos({required bool completed}) async {
    if (kIsWeb) {
      final List<TodoItem> rows = _webItems
          .where((TodoItem item) => item.isCompleted == completed)
          .toList(growable: false);
      rows.sort((TodoItem a, TodoItem b) => a.dueAt.compareTo(b.dueAt));
      return rows;
    }

    final Database db = await _dbHelper.open();

    final List<Map<String, Object?>> rows = await db.query(
      DbHelper.tableTodo,
      where: 'is_completed = ?',
      whereArgs: <Object>[completed ? 1 : 0],
      orderBy: 'due_at ASC',
    );

    return rows.map(TodoItem.fromMap).toList(growable: false);
  }

  Future<List<TodoItem>> getTodosByCourseName(String courseName) async {
    if (kIsWeb) {
      final List<TodoItem> rows = _webItems
          .where((TodoItem item) => item.courseName == courseName)
          .toList(growable: false);
      rows.sort((TodoItem a, TodoItem b) => a.dueAt.compareTo(b.dueAt));
      return rows;
    }

    final Database db = await _dbHelper.open();

    final List<Map<String, Object?>> rows = await db.query(
      DbHelper.tableTodo,
      where: 'course_name = ?',
      whereArgs: <Object>[courseName],
      orderBy: 'due_at ASC',
    );

    return rows.map(TodoItem.fromMap).toList(growable: false);
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
        courseName: current.courseName,
        dueAt: current.dueAt,
        isCompleted: isCompleted,
        createdAt: current.createdAt,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
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
  }

  Future<void> deleteTodo(int id) async {
    if (kIsWeb) {
      _webItems.removeWhere((TodoItem item) => item.id == id);
      return;
    }

    final Database db = await _dbHelper.open();
    await db.delete(
      DbHelper.tableTodo,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> deleteTodosByTaskType(String taskType) async {
    if (kIsWeb) {
      _webItems.removeWhere((TodoItem item) => item.taskType == taskType);
      return;
    }

    final Database db = await _dbHelper.open();
    await db.delete(
      DbHelper.tableTodo,
      where: 'task_type = ?',
      whereArgs: <Object>[taskType],
    );
  }
}
