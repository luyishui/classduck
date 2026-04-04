import 'dart:convert';

import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/course.dart';
import '../../schedule/domain/course_table.dart';
import '../data/import_api_service.dart';
import '../domain/import_course.dart';
import '../domain/import_table.dart';
import '../domain/school_config.dart';
import 'ai_import_parser.dart';
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

enum ImportConflictMode { createNew, overwriteExisting, appendToCurrent }

class ImportEngine {
  ImportEngine({
    ScheduleRepository? scheduleRepository,
    ImportApiService? apiService,
  }) : _scheduleRepository = scheduleRepository ?? ScheduleRepository(),
       _apiService = apiService ?? ImportApiService();

  final ScheduleRepository _scheduleRepository;
  final ImportApiService _apiService;

  // ────────────────────────────────────────────
  // 新通路：WebView 中 JS 拿到原始 JSON → 后端校验
  // ────────────────────────────────────────────

  /// 把从 WebView JS 拿到的原始课表 JSON 发到后端校验，
  /// 后端返回标准化课程列表后存入本地 SQLite。
  ///
  /// 【实现思路】
  /// 1. 调用 ImportApiService.validateImport() 将 rawJson POST 到
  ///    Python 后端 /api/import/validate 接口。
  /// 2. 后端按学校配置的 field_mapping 做字段映射、周次/节次解析，
  ///    返回标准化的 {courses[], valid_count, invalid_count, warnings}。
  /// 3. 前端解析返回的 courses 数组，映射为 ImportCourse 领域对象，
  ///    再调用 _storeParsedTable() 写入本地 SQLite。
  /// 4. 若后端返回 success=false 或 courses 为空，抛出 StateError 中断导入。
  ///
  /// 与旧通路的差异在于：解析逻辑从 Dart 侧移到了 Python 后端，
  /// Dart 只负责"组装请求 → 接收标准化结果 → 存库"。
  Future<ImportExecutionResult> importFromRawJson(
    SchoolConfig config, {
    required String rawJson,
    String year = '',
    String term = '',
    String? schoolIdOverride,
    ImportConflictMode mode = ImportConflictMode.createNew,
  }) async {
    final String validateSchoolId =
        (schoolIdOverride ?? config.id).trim().isEmpty
        ? config.id
        : (schoolIdOverride ?? config.id).trim();

    final Map<String, dynamic> validated = await _apiService.validateImport(
      schoolId: validateSchoolId,
      rawData: rawJson,
      year: year,
      term: term,
    );

    if (validated['success'] != true) {
      final String errorMsg = validated['error'] as String? ?? '后端校验失败';
      throw StateError(errorMsg);
    }

    final Map<String, dynamic> data = validated['data'] as Map<String, dynamic>;
    final List<dynamic> coursesRaw =
        data['courses'] as List<dynamic>? ?? <dynamic>[];
    final String semesterName = data['semester_name'] as String? ?? '';

    if (coursesRaw.isEmpty) {
      throw StateError('后端校验通过但课程为空，请确认学年学期是否正确');
    }

    final List<ImportCourse> courses = coursesRaw
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> item) {
          return ImportCourse(
            name: item['name'] as String? ?? '',
            classroom: item['position'] as String?,
            teacher: item['teacher'] as String?,
            weeks: (item['weeks'] as List<dynamic>? ?? <dynamic>[])
                .whereType<int>()
                .toList(growable: false),
            weekTime: item['day'] as int? ?? 1,
            startTime: item['start_section'] as int? ?? 1,
            timeCount: item['duration'] as int? ?? 1,
          );
        })
        .toList(growable: false);

    final String tableName = semesterName.isNotEmpty
        ? semesterName
        : 'Imported - ${config.displayTitle}';

    final ImportTable parsed = ImportTable(name: tableName, courses: courses);
    return _storeParsedTable(parsed, mode: mode);
  }

  // ────────────────────────────────────────────
  // 旧通路（保留）：抓 HTML → Dart 本地解析
  // ────────────────────────────────────────────

  Future<ImportExecutionResult> importFromSchoolConfig(
    SchoolConfig config, {
    ImportConflictMode mode = ImportConflictMode.createNew,
  }) async {
    final ImportTable parsed = await _executeParser(config);
    return _storeParsedTable(parsed, mode: mode);
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

    return _storeParsedTable(parsed, mode: mode);
  }

  // ────────────────────────────────────────────
  // AI 导入通路：用户粘贴 AI 返回的 JSON 文本 → 本地解析 → 存库
  //
  // 【实现思路】
  // 1. 调用 AiImportParser.parse() 对用户粘贴的原始文本进行 JSON 提取与结构化解析。
  // 2. 解析器能容忍 markdown 代码块包裹、多种字段命名风格、中文星期/周次等。
  // 3. 解析成功后得到 ImportTable（含课表名 + ImportCourse 列表），
  //    交由 _storeParsedTable() 写入 SQLite。
  // 4. 此通路完全离线，不依赖后端。
  // ────────────────────────────────────────────

  Future<ImportExecutionResult> importFromAiText(
    String text, {
    String tableName = 'AI导入课表',
    ImportConflictMode mode = ImportConflictMode.createNew,
  }) async {
    final ImportTable parsed = AiImportParser.parse(
      text,
      fallbackTableName: tableName,
    );
    return _storeParsedTable(parsed, mode: mode);
  }

  // ────────────────────────────────────────────
  // 共用：将解析好的 ImportTable 写入本地 SQLite
  // ────────────────────────────────────────────

  /// 新旧通路共用的存储方法。
  ///
  /// 【实现思路】
  /// 1. 若冲突模式为 overwriteExisting，先清空所有课表——
  ///    因为用户选择了"覆盖当前课表"。
  /// 2. 在 schedule_repository 创建一张新课表（name = 学期名或学校名）。
  /// 3. 将 ImportCourse 列表转为 CourseEntity 列表写入该课表。
  /// 4. 返回 ImportExecutionResult 包含 tableId、tableName、导入数量。

  Future<ImportExecutionResult> _storeParsedTable(
    ImportTable parsed, {
    ImportConflictMode mode = ImportConflictMode.createNew,
  }) async {
    final String now = DateTime.now().toUtc().toIso8601String();
    if (mode == ImportConflictMode.appendToCurrent) {
      final int? activeTableId = ScheduleRepository.activeTableId;
      if (activeTableId != null) {
        await _scheduleRepository.addCourses(
          tableId: activeTableId,
          courses: _buildCourseEntities(
            parsed: parsed,
            tableId: activeTableId,
            now: now,
          ),
        );

        String tableName = '当前课表';
        final List<CourseTableEntity> tables = await _scheduleRepository
            .getCourseTables();
        for (final CourseTableEntity table in tables) {
          if (table.id == activeTableId) {
            tableName = table.name;
            break;
          }
        }

        return ImportExecutionResult(
          courseTableId: activeTableId,
          tableName: tableName,
          importedCount: parsed.courses.length,
        );
      }
    }

    if (mode == ImportConflictMode.overwriteExisting) {
      await _scheduleRepository.clearAllCourseTables();
    }

    final String uniqueTableName = await _resolveUniqueTableName(parsed.name);

    final created = await _scheduleRepository.createCourseTable(
      name: uniqueTableName,
      enforceUniqueName: true,
    );

    await _scheduleRepository.addCourses(
      tableId: created.id!,
      courses: _buildCourseEntities(
        parsed: parsed,
        tableId: created.id!,
        now: now,
      ),
    );

    return ImportExecutionResult(
      courseTableId: created.id!,
      tableName: uniqueTableName,
      importedCount: parsed.courses.length,
    );
  }

  Future<String> _resolveUniqueTableName(String rawName) async {
    final String baseName = rawName.trim().isEmpty ? '导入课表' : rawName.trim();
    if (!await _scheduleRepository.isCourseTableNameTaken(baseName)) {
      return baseName;
    }

    int suffix = 2;
    while (true) {
      final String candidate = '$baseName($suffix)';
      if (!await _scheduleRepository.isCourseTableNameTaken(candidate)) {
        return candidate;
      }
      suffix++;
    }
  }

  List<CourseEntity> _buildCourseEntities({
    required ImportTable parsed,
    required int tableId,
    required String now,
  }) {
    return parsed.courses
        .map((ImportCourse item) {
          return CourseEntity(
            tableId: tableId,
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
        })
        .toList(growable: false);
  }

  Future<ImportTable> _executeParser(SchoolConfig config) async {
    // This is a transition implementation.
    // Real WebView + JS parser execution will replace this mocked parser result.
    return ImportTable(
      name: 'Imported - ${config.displayTitle}',
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
    final String source =
        '${config.id} ${config.title} ${pageUrl.toLowerCase()}';
    if (source.contains('西安交通') ||
        source.contains('xjtu') ||
        source.contains('gmis.xjtu.edu.cn')) {
      return XjtuScheduleHtmlParser.parse(
        html,
        schoolName: config.displayTitle,
      );
    }

    throw UnsupportedError('该学校暂未完成抓取解析器：${config.displayTitle}');
  }
}
