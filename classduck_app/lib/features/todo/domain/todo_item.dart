class TodoItem {
  TodoItem({
    this.id,
    required this.title,
    required this.taskType,
    this.tableId,
    this.courseName,
    required this.dueAt,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String taskType;
  final int? tableId;
  final String? courseName;
  final String dueAt;
  final bool isCompleted;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'task_type': taskType,
      'table_id': tableId,
      'course_name': courseName,
      'due_at': dueAt,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory TodoItem.fromMap(Map<String, Object?> map) {
    return TodoItem(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      taskType: map['task_type'] as String? ?? 'assignment',
      tableId: map['table_id'] as int?,
      courseName: map['course_name'] as String?,
      dueAt: map['due_at'] as String? ?? '',
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
