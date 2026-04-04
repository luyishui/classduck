import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../data/remote/http_json_client.dart';
import '../domain/school_config.dart';

/// 学校配置仓库。
///
/// 采用“后端配置优先，本地内置兜底”的合并策略：
/// - Python 后端返回的学校配置用于真实适配和动态更新。
/// - `schools.builtin.json` 用于后端只配置少量学校时保持列表完整。
class SchoolConfigRepository {
  SchoolConfigRepository({HttpJsonClient? client})
    : _client =
          client ?? HttpJsonClient(requestTimeout: const Duration(seconds: 3));

  final HttpJsonClient _client;

  static const Set<String> _wakeupRuleAliases = <String>{
    'wakeup_type_zf',
    'wakeup_type_zf_new',
    'wakeup_type_qz',
    'wakeup_type_urp',
    'wakeup_type_urp_new',
    'wakeup_type_cf',
    'wakeup_type_pku',
    'wakeup_type_pku_master',
  };

  static const Map<String, List<String>> _fallbackFusionRules =
      <String, List<String>>{
        'wakeup_type_zf': <String>['zhengfang_01'],
        'wakeup_type_zf_new': <String>['zhengfang_01'],
        'wakeup_type_qz': <String>['qingguo_01'],
        'wakeup_type_urp': <String>['urp_01'],
        'wakeup_type_urp_new': <String>['urp_01'],
        'wakeup_type_cf': <String>['qingguo_01'],
        'wakeup_type_pku': <String>['zhengfang_01'],
        'wakeup_type_pku_master': <String>['zhengfang_01'],
      };

  static List<SchoolConfig> decodeBuiltinPayload(String raw) {
    final String normalized = raw.startsWith('\uFEFF') ? raw.substring(1) : raw;
    final dynamic decoded = jsonDecode(normalized);
    if (decoded is! Map<String, dynamic>) {
      return <SchoolConfig>[];
    }

    final dynamic list = decoded['data'];
    if (list is! List<dynamic>) {
      return <SchoolConfig>[];
    }

    return list
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .map(SchoolConfig.fromMap)
        .toList(growable: false);
  }

  static List<SchoolConfig> dedupeByDisplayTitle(Iterable<SchoolConfig> input) {
    final Map<String, SchoolConfig> deduped = <String, SchoolConfig>{};
    for (final SchoolConfig config in input) {
      final String key = '${config.level}|${config.normalizedDisplayTitleKey}';
      final SchoolConfig? existing = deduped[key];
      if (existing == null || _qualityScore(config) > _qualityScore(existing)) {
        deduped[key] = config;
      }
    }
    return deduped.values.toList(growable: false);
  }

  static int _qualityScore(SchoolConfig config) {
    int score = 0;
    final String initial = config.initialUrl.trim().toLowerCase();
    final String target = config.targetUrl.trim().toLowerCase();
    final String script = config.extractScriptUrl.trim().toLowerCase();

    if (script.isNotEmpty && !script.startsWith('local://')) {
      score += 3;
    }
    if (initial.isNotEmpty && !initial.contains('example.com')) {
      score += 3;
    }
    if (target.isNotEmpty && !target.contains('example.com')) {
      score += 1;
    }
    if (config.id.toLowerCase().startsWith('ais_')) {
      score -= 1;
    }
    if (_wakeupRuleAliases.contains(config.id)) {
      score += 4;
    }
    return score;
  }

  static List<SchoolConfig> fuseGeneralWakeupRules(List<SchoolConfig> input) {
    final Map<String, SchoolConfig> byId = <String, SchoolConfig>{
      for (final SchoolConfig config in input) config.id: config,
    };
    final Set<String> hiddenFallbackIds = <String>{};

    for (final MapEntry<String, List<String>> entry
        in _fallbackFusionRules.entries) {
      final SchoolConfig? alias = byId[entry.key];
      if (alias == null) {
        continue;
      }

      final List<String> mergedCandidates = <String>[];
      final Set<String> seen = <String>{};

      for (final String schoolId in alias.executionSchoolIds) {
        if (schoolId.isEmpty ||
            !byId.containsKey(schoolId) ||
            seen.contains(schoolId)) {
          continue;
        }
        seen.add(schoolId);
        mergedCandidates.add(schoolId);
        hiddenFallbackIds.add(schoolId);
      }

      for (final String schoolId in entry.value) {
        if (schoolId.isEmpty ||
            !byId.containsKey(schoolId) ||
            seen.contains(schoolId)) {
          continue;
        }
        seen.add(schoolId);
        mergedCandidates.add(schoolId);
        hiddenFallbackIds.add(schoolId);
      }

      if (mergedCandidates.isNotEmpty) {
        byId[entry.key] = alias.copyWith(executionSchoolIds: mergedCandidates);
      }
    }

    final List<SchoolConfig> result = <SchoolConfig>[];
    for (final SchoolConfig config in input) {
      if (hiddenFallbackIds.contains(config.id)) {
        continue;
      }
      result.add(byId[config.id] ?? config);
    }
    return result;
  }

  /// 合并策略：API 返回的数据优先，再补充内置数据中没有覆盖到的学校。
  /// 这样后端只配了少量学校时，内置学校仍然能展示。
  Future<List<SchoolConfig>> fetchSchoolConfigs({
    List<SchoolConfig>? builtinSeed,
  }) async {
    final List<SchoolConfig> builtinConfigs = builtinSeed ?? await _loadBuiltinConfigs();
    List<SchoolConfig> apiConfigs = <SchoolConfig>[];

    try {
      final Map<String, dynamic> payload = await _client
          .getJsonMap('/v1/config/schools')
          .timeout(const Duration(milliseconds: 1200));
      final dynamic rawList =
          payload['data'] ?? payload['schools'] ?? payload['items'] ?? payload;
      if (rawList is List<dynamic>) {
        apiConfigs = rawList
            .whereType<Map>()
            .map((Map item) => Map<String, dynamic>.from(item))
            .map(SchoolConfig.fromMap)
            .toList(growable: false);
      }
    } catch (_) {
      // API 不可用时仅使用内置数据
    }

    // 先以 API 数据为优先按 id 去重，再按“层级 + 学校展示名”去重，
    // 避免同校多条来源同时展示造成混乱。
    final Map<String, SchoolConfig> merged = <String, SchoolConfig>{};
    for (final SchoolConfig config in builtinConfigs) {
      merged[config.id] = config;
    }
    for (final SchoolConfig config in apiConfigs) {
      merged[config.id] = config;
    }

    final List<SchoolConfig> fused = fuseGeneralWakeupRules(
      merged.values.toList(growable: false),
    );

    return dedupeByDisplayTitle(fused);
  }

  Future<List<SchoolConfig>> loadBuiltinConfigs() {
    return _loadBuiltinConfigs();
  }

  Future<List<SchoolConfig>> _loadBuiltinConfigs() async {
    try {
      final String raw = await rootBundle.loadString(
        'assets/config/schools.builtin.json',
      );
      return decodeBuiltinPayload(raw);
    } catch (_) {
      return <SchoolConfig>[];
    }
  }
}
