class CourseTableEntity {
  CourseTableEntity({
    this.id,
    required this.name,
    this.semesterStartMonday,
    this.classTimeListJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? semesterStartMonday;
  final String? classTimeListJson;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'semester_start_monday': semesterStartMonday,
      'class_time_list_json': classTimeListJson,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CourseTableEntity.fromMap(Map<String, Object?> map) {
    return CourseTableEntity(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      semesterStartMonday: map['semester_start_monday'] as String?,
      classTimeListJson: map['class_time_list_json'] as String?,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }
}
