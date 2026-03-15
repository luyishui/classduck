import 'dart:convert';

import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/course.dart';
import '../domain/import_course.dart';
import '../domain/import_table.dart';
import '../domain/school_config.dart';
import 'xjtu_schedule_html_parser.dart';

class ImportExecutionResult {
  ImportExecutionResult({
    required this.courseTableId,
    required this.tableName,
    required this.importedCount,
  });

  final int courseTableId;
  final String tableName;
  final int importedCount;
}

enum ImportConflictMode {
  createNew,
  overwriteExisting,
}

class ImportEngine {
  ImportEngine({ScheduleRepository? scheduleRepository})
      : _scheduleRepository = scheduleRepository ?? ScheduleRepository();

  final ScheduleRepository _scheduleRepository;

  Future<ImportExecutionResult> importFromSchoolConfig(
    SchoolConfig config, {
    ImportConflictMode mode = ImportConflictMode.createNew,
  }) async {
    final ImportTable parsed = await _executeParser(config);

    if (mode == ImportConflictMode.overwriteExisting) {
      await _scheduleRepository.clearAllCourseTables();
    }

    final created = await _scheduleRepository.createCourseTable(name: parsed.name);
    final String now = DateTime.now().toUtc().toIso8601String();

    await _scheduleRepository.addCourses(
      tableId: created.id!,
      courses: parsed.courses.map((ImportCourse item) {
        return CourseEntity(
          tableId: created.id!,
          name: item.name,
          classroom: item.classroom,
          classNumber: item.classNumber,
          teacher: item.teacher,
          weeksJson: jsonEncode(item.weeks),
          weekTime: item.weekTime,
          startTime: item.startTime,
          timeCount: item.timeCount,
          importType: 1,
          createdAt: now,
          updatedAt: now,
        );
      }).toList(growable: false),
    );

    return ImportExecutionResult(
      courseTableId: created.id!,
      tableName: parsed.name,
      importedCount: parsed.courses.length,
    );
  }

  Future<ImportExecutionResult> importFromCapturedHtml(
    SchoolConfig config, {
    required String html,
    required String pageUrl,
    ImportConflictMode mode = ImportConflictMode.createNew,
  }) async {
    final ImportTable parsed = _executeParserFromCapturedHtml(
      config,
      html: html,
      pageUrl: pageUrl,
    );

    if (parsed.courses.isEmpty) {
      throw StateError('未解析到课程，请确认已进入课表页面。');
    }

    if (mode == ImportConflictMode.overwriteExisting) {
      await _scheduleRepository.clearAllCourseTables();
    }

    final created = await _scheduleRepository.createCourseTable(name: parsed.name);
    final String now = DateTime.now().toUtc().toIso8601String();

    await _scheduleRepository.addCourses(
      tableId: created.id!,
      courses: parsed.courses.map((ImportCourse item) {
        return CourseEntity(
          tableId: created.id!,
          name: item.name,
          classroom: item.classroom,
          classNumber: item.classNumber,
          teacher: item.teacher,
          weeksJson: jsonEncode(item.weeks),
          weekTime: item.weekTime,
          startTime: item.startTime,
          timeCount: item.timeCount,
          importType: 1,
          createdAt: now,
          updatedAt: now,
        );
      }).toList(growable: false),
    );

    return ImportExecutionResult(
      courseTableId: created.id!,
      tableName: parsed.name,
      importedCount: parsed.courses.length,
    );
  }

  Future<ImportTable> _executeParser(SchoolConfig config) async {
    // This is a transition implementation.
    // Real WebView + JS parser execution will replace this mocked parser result.
    return ImportTable(
      name: 'Imported - ${config.title}',
      courses: <ImportCourse>[
        ImportCourse(
          name: 'Imported Math',
          classroom: 'Teaching Building 1-201',
          classNumber: 'IMP-MATH-01',
          teacher: 'Teacher Chen',
          weeks: <int>[1, 2, 3, 4, 5, 6, 7, 8],
          weekTime: 1,
          startTime: 1,
          timeCount: 2,
        ),
        ImportCourse(
          name: 'Imported English',
          classroom: 'Teaching Building 2-306',
          classNumber: 'IMP-ENG-01',
          teacher: 'Teacher Wang',
          weeks: <int>[1, 2, 3, 4, 5, 6, 7, 8],
          weekTime: 3,
          startTime: 3,
          timeCount: 2,
        ),
      ],
    );
  }

  ImportTable _executeParserFromCapturedHtml(
    SchoolConfig config, {
    required String html,
    required String pageUrl,
  }) {
    final String source = '${config.id} ${config.title} ${pageUrl.toLowerCase()}';
    if (source.contains('西安交通') || source.contains('xjtu') || source.contains('gmis.xjtu.edu.cn')) {
      return XjtuScheduleHtmlParser.parse(html, schoolName: config.title);
    }

    throw UnsupportedError('该学校暂未完成抓取解析器：${config.title}');
  }
}
