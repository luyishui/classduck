import 'dart:convert';

import 'package:classduck_app/features/schedule/data/schedule_repository.dart';
import 'package:classduck_app/features/schedule/domain/course.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('createCourseTable and addCourses persist records', () async {
    final ScheduleRepository repository = ScheduleRepository();
    await repository.clearAllCourseTables();

    final table = await repository.createCourseTable(name: '测试课表');
    final String now = DateTime.now().toUtc().toIso8601String();

    await repository.addCourses(
      tableId: table.id!,
      courses: <CourseEntity>[
        CourseEntity(
          tableId: table.id!,
          name: '高等数学',
          classroom: 'A101',
          teacher: '张老师',
          weeksJson: jsonEncode(<int>[1, 2, 3]),
          weekTime: 1,
          startTime: 1,
          timeCount: 2,
          importType: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final tables = await repository.getCourseTables();
    final courses = await repository.getCoursesByTableId(table.id!);

    expect(tables.any((item) => item.id == table.id), isTrue);
    expect(courses, hasLength(1));
    expect(courses.first.name, '高等数学');

    await repository.clearAllCourseTables();
  });

  test('custom table creation rejects duplicated names', () async {
    final ScheduleRepository repository = ScheduleRepository();
    await repository.clearAllCourseTables();

    await repository.createCourseTable(name: '我的课表', enforceUniqueName: true);

    expect(
      repository.createCourseTable(name: '  我的课表  ', enforceUniqueName: true),
      throwsA(isA<StateError>()),
    );

    await repository.clearAllCourseTables();
  });

  test('renameCourseTable rejects duplicated names', () async {
    final ScheduleRepository repository = ScheduleRepository();
    await repository.clearAllCourseTables();

    final tableA = await repository.createCourseTable(name: '课表A');
    final tableB = await repository.createCourseTable(name: '课表B');

    expect(
      repository.renameCourseTable(tableId: tableB.id!, newName: tableA.name),
      throwsA(isA<StateError>()),
    );

    await repository.clearAllCourseTables();
  });
}
