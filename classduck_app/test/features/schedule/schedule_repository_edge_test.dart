import 'package:classduck_app/features/schedule/data/schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('clearAllCourseTables removes previously created tables', () async {
    final ScheduleRepository repository = ScheduleRepository();
    await repository.clearAllCourseTables();

    await repository.createCourseTable(name: '课表A');
    expect(await repository.getCourseTables(), isNotEmpty);

    await repository.clearAllCourseTables();

    final tables = await repository.getCourseTables();
    expect(tables, isEmpty);
  });
}