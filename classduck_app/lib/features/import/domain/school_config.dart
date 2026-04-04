/// 导入学校配置的前端领域模型。
///
/// 当前结构兼容两类来源：
/// 1. Python 后端 `/v1/config/schools` 返回的数据。
/// 2. 本地 `schools.builtin.json` 的静态兜底数据。
class SchoolConfig {
  SchoolConfig({
    required this.id,
    required this.level,
    required this.title,
    required this.initialUrl,
    required this.targetUrl,
    required this.extractScriptUrl,
    required this.delaySeconds,
    List<String>? executionSchoolIds,
  }) : executionSchoolIds = _normalizeExecutionSchoolIds(
         id,
         executionSchoolIds,
       );

  final String id;
  final String level;
  final String title;
  final String initialUrl;
  final String targetUrl;
  final String extractScriptUrl;
  final int delaySeconds;
  final List<String> executionSchoolIds;

  String get displayTitle =>
      normalizeDisplayTitle(title, keepJiaowuSuffix: level == 'general');

  /// 供导入执行使用的 school_id 候选链。
  ///
  /// 规则：
  /// 1. 若配置显式提供 executionSchoolIds，则按该顺序执行。
  /// 2. 否则回退为当前配置 id。
  List<String> get executableSchoolIds {
    if (executionSchoolIds.isEmpty) {
      return <String>[id];
    }
    return executionSchoolIds;
  }

  String get normalizedDisplayTitleKey {
    final String normalized = displayTitle.toLowerCase().replaceAll(
      RegExp(r'[^0-9a-z\u4e00-\u9fff]+'),
      '',
    );
    return normalized.isEmpty
        ? id.toLowerCase().replaceAll(RegExp(r'[^0-9a-z]+'), '')
        : normalized;
  }

  static String normalizeDisplayTitle(
    String rawTitle, {
    bool keepJiaowuSuffix = false,
  }) {
    String value = rawTitle.trim();
    if (value.isEmpty) {
      return value;
    }

    value = value
        .replaceAll(
          RegExp(
            r'\s*[（(][^）)]*(AIShedule|AISchedule|AI\s*Schedule|test|beta)[^）)]*[）)]',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // 保留“XX大学YY分校/YY校区”这类校区信息，避免被简化为同校主名称后误去重。
    final Match? campusMatch = RegExp(
      r'^(.+?(?:大学|学院|学校)[^（）()]{0,12}?(?:分校|校区))',
    ).firstMatch(value);
    if (campusMatch != null) {
      final String campusTitle = (campusMatch.group(1) ?? '').trim();
      if (campusTitle.isNotEmpty) {
        return campusTitle;
      }
    }

    // 优先提取标准学校主体名，避免显示“XX教务系统”“XX选课系统”等系统后缀。
    const List<String> schoolMarkers = <String>[
      '职业技术学院',
      '高等专科学校',
      '专科学校',
      '职业学院',
      '研究生院',
      '大学',
      '学院',
      '学校',
    ];
    for (final String marker in schoolMarkers) {
      final int index = value.indexOf(marker);
      if (index >= 0) {
        final String candidate = value
            .substring(0, index + marker.length)
            .trim();
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }

    if (keepJiaowuSuffix) {
      value = value
          .replaceAll(RegExp(r'(研究生|本科生|硕士|本研)?(教育)?(信息)?(管理)?系统$'), '')
          .trim();
      value = value.replaceAll(RegExp(r'(选课|课表)$'), '').trim();
    } else {
      value = value
          .replaceAll(
            RegExp(r'(研究生|本科生|硕士|本研)?(教育)?(信息)?(管理)?(教务|选课|课表)?系统$'),
            '',
          )
          .trim();
      value = value.replaceAll(RegExp(r'(教务|选课|课表)$'), '').trim();
    }
    return value.isEmpty ? rawTitle.trim() : value;
  }

  SchoolConfig copyWith({
    String? id,
    String? level,
    String? title,
    String? initialUrl,
    String? targetUrl,
    String? extractScriptUrl,
    int? delaySeconds,
    List<String>? executionSchoolIds,
  }) {
    return SchoolConfig(
      id: id ?? this.id,
      level: level ?? this.level,
      title: title ?? this.title,
      initialUrl: initialUrl ?? this.initialUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      extractScriptUrl: extractScriptUrl ?? this.extractScriptUrl,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      executionSchoolIds: executionSchoolIds ?? this.executionSchoolIds,
    );
  }

  /// 从后端/本地配置对象解析为统一模型。
  factory SchoolConfig.fromMap(Map<String, dynamic> map) {
    final dynamic executionIds =
        map['executionSchoolIds'] ?? map['fallbackSchoolIds'];
    return SchoolConfig(
      id: map['id'] as String? ?? '',
      // 优先读取后端 level 字段；若旧配置未提供则按 id/title 进行兼容推断。
      level: _normalizeLevel(
        rawLevel: map['level'] as String?,
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
      ),
      title: map['title'] as String? ?? '',
      initialUrl: map['initialUrl'] as String? ?? '',
      targetUrl: map['targetUrl'] as String? ?? '',
      extractScriptUrl: map['extractScriptUrl'] as String? ?? '',
      delaySeconds: map['delaySeconds'] as int? ?? 0,
      executionSchoolIds: executionIds is List<dynamic>
          ? executionIds
                .whereType<String>()
                .map((String item) => item.trim())
                .where((String item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
  }

  /// 对学校层级做兼容归一化，避免旧配置缺字段时前端分栏失效。
  static String _normalizeLevel({
    required String? rawLevel,
    required String id,
    required String title,
  }) {
    const Set<String> valid = <String>{
      'undergraduate',
      'master',
      'general',
      'junior',
    };
    final String normalized = (rawLevel ?? '').trim().toLowerCase();
    if (normalized == 'junior') {
      // 产品分栏调整：专科并入“本/专科”。
      return 'undergraduate';
    }
    if (valid.contains(normalized)) {
      return normalized;
    }

    final String source =
        '${(rawLevel ?? '').toLowerCase()} ${id.toLowerCase()} ${title.toLowerCase()}';
    if (source.contains('master') ||
        source.contains('硕士') ||
        source.contains('研究生')) {
      return 'master';
    }
    if (source.contains('junior') ||
        source.contains('专科') ||
        source.contains('高职')) {
      return 'undergraduate';
    }
    if (source.contains('undergraduate') ||
        source.contains('本科') ||
        source.contains('大学') ||
        source.contains('学院') ||
        source.contains('学校')) {
      return 'undergraduate';
    }
    return 'general';
  }

  static List<String> _normalizeExecutionSchoolIds(
    String id,
    List<String>? executionSchoolIds,
  ) {
    final List<String> source = executionSchoolIds ?? const <String>[];
    final Set<String> seen = <String>{};
    final List<String> normalized = <String>[];
    for (final String item in source) {
      final String value = item.trim();
      if (value.isEmpty || value == id || seen.contains(value)) {
        continue;
      }
      seen.add(value);
      normalized.add(value);
    }
    return normalized;
  }
}
