import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../data/remote/http_json_client.dart';
import '../domain/school_config.dart';

/// 学校配置仓库。
///
/// 采用“后端配置优先，本地内置兜底”的合并策略：
/// - Python 后端返回的学校配置用于真实适配和动态更新。
/// - `schools.builtin.json` 用于后端只配置少量学校时保持列表完整。
///
/// 这能同时满足开发联调和产品展示，不会因为后端样例数据太少导致学校列表为空。
class SchoolConfigRepository {
  SchoolConfigRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  /// 合并策略：API 返回的数据优先，再补充内置数据中没有覆盖到的学校。
  /// 这样后端只配了少量学校时，内置的 82 所仍然能展示。
  Future<List<SchoolConfig>> fetchSchoolConfigs() async {
    final List<SchoolConfig> builtinConfigs = await _loadBuiltinConfigs();
    List<SchoolConfig> apiConfigs = <SchoolConfig>[];

    try {
      final Map<String, dynamic> payload = await _client.getJsonMap('/v1/config/schools');
      final dynamic list = payload['data'];
      if (list is List<dynamic>) {
        apiConfigs = list
            .whereType<Map<String, dynamic>>()
            .map(SchoolConfig.fromMap)
            .toList(growable: false);
      }
    } catch (_) {
      // API 不可用时仅使用内置数据
    }

    // 以 API 数据为优先：按 id 去重，API 中已有的学校覆盖内置版本
    final Map<String, SchoolConfig> merged = <String, SchoolConfig>{};
    for (final SchoolConfig config in builtinConfigs) {
      merged[config.id] = config;
    }
    for (final SchoolConfig config in apiConfigs) {
      merged[config.id] = config;
    }

    return merged.values.toList(growable: false);
  }

  Future<List<SchoolConfig>> _loadBuiltinConfigs() async {
    try {
      final String raw = await rootBundle.loadString('assets/config/schools.builtin.json');
      final Map<String, dynamic> payload = jsonDecode(raw) as Map<String, dynamic>;
      final dynamic list = payload['data'];

      if (list is! List<dynamic>) {
        return <SchoolConfig>[];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(SchoolConfig.fromMap)
          .toList(growable: false);
    } catch (_) {
      return <SchoolConfig>[];
    }
  }
}
