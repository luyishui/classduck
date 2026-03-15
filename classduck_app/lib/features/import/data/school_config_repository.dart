import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../data/remote/http_json_client.dart';
import '../domain/school_config.dart';

class SchoolConfigRepository {
  SchoolConfigRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  Future<List<SchoolConfig>> fetchSchoolConfigs() async {
    try {
      final Map<String, dynamic> payload = await _client.getJsonMap('/v1/config/schools');
      final dynamic list = payload['data'];

      if (list is! List<dynamic>) {
        return <SchoolConfig>[];
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map(SchoolConfig.fromMap)
          .toList(growable: false);
    } catch (_) {
      // 本地内置兜底：便于未启动后端时也可调试导入学校列表。
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
    }
  }
}
