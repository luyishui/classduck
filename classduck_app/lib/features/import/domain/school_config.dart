class SchoolConfig {
  SchoolConfig({
    required this.id,
    required this.level,
    required this.title,
    required this.initialUrl,
    required this.targetUrl,
    required this.extractScriptUrl,
    required this.delaySeconds,
  });

  final String id;
  final String level;
  final String title;
  final String initialUrl;
  final String targetUrl;
  final String extractScriptUrl;
  final int delaySeconds;

  factory SchoolConfig.fromMap(Map<String, dynamic> map) {
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
    );
  }

  static String _normalizeLevel({
    required String? rawLevel,
    required String id,
    required String title,
  }) {
    const Set<String> valid = <String>{'undergraduate', 'master', 'general', 'junior'};
    final String normalized = (rawLevel ?? '').trim().toLowerCase();
    if (normalized == 'junior') {
      // 产品分栏调整：专科并入“本/专科”。
      return 'undergraduate';
    }
    if (valid.contains(normalized)) {
      return normalized;
    }

    final String source = '${id.toLowerCase()} ${title.toLowerCase()}';
    if (source.contains('master') || source.contains('硕士') || source.contains('研究生')) {
      return 'master';
    }
    if (source.contains('junior') || source.contains('专科') || source.contains('高职')) {
      return 'undergraduate';
    }
    if (source.contains('undergraduate') || source.contains('本科') || source.contains('大学') || source.contains('学院') || source.contains('学校')) {
      return 'undergraduate';
    }
    return 'general';
  }
}
