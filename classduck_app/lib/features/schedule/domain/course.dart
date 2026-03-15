class CourseEntity {
  CourseEntity({
    this.id,
    required this.tableId,
    required this.name,
    this.classroom,
    this.classNumber,
    this.teacher,
    this.testTime,
    this.testLocation,
    this.infoLink,
    this.info,
    required this.weeksJson,
    required this.weekTime,
    required this.startTime,
    required this.timeCount,
    required this.importType,
    this.colorHex,
    this.courseId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int tableId;
  final String name;
  final String? classroom;
  final String? classNumber;
  final String? teacher;
  final String? testTime;
  final String? testLocation;
  final String? infoLink;
  final String? info;
  final String weeksJson;
  final int weekTime;
  final int startTime;
  final int timeCount;
  final int importType;
  final String? colorHex;
  final int? courseId;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'table_id': tableId,
      'name': name,
      'classroom': classroom,
      'class_number': classNumber,
      'teacher': teacher,
      'test_time': testTime,
      'test_location': testLocation,
      'info_link': infoLink,
      'info': info,
      'weeks_json': weeksJson,
      'week_time': weekTime,
      'start_time': startTime,
      'time_count': timeCount,
      'import_type': importType,
      'color_hex': colorHex,
      'course_id': courseId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CourseEntity.fromMap(Map<String, Object?> map) {
    return CourseEntity(
      id: map['id'] as int?,
      tableId: map['table_id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      classroom: map['classroom'] as String?,
      classNumber: map['class_number'] as String?,
      teacher: map['teacher'] as String?,
      testTime: map['test_time'] as String?,
      testLocation: map['test_location'] as String?,
      infoLink: map['info_link'] as String?,
      info: map['info'] as String?,
      weeksJson: map['weeks_json'] as String? ?? '[]',
      weekTime: map['week_time'] as int? ?? 0,
      startTime: map['start_time'] as int? ?? 0,
      timeCount: map['time_count'] as int? ?? 0,
      importType: map['import_type'] as int? ?? 0,
      colorHex: map['color_hex'] as String?,
      courseId: map['course_id'] as int?,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
