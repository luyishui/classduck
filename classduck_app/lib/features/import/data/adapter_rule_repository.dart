import '../../../data/remote/http_json_client.dart';

class AdapterRuleRepository {
  AdapterRuleRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  Future<AdapterRuleListResult> fetchRules() async {
    final Map<String, dynamic> payload = await _client.getJsonMap('/v1/config/adapters');
    return AdapterRuleListResult.fromMap(payload);
  }
}

class AdapterRuleListResult {
  AdapterRuleListResult({
    required this.version,
    required this.rules,
  });

  final String version;
  final List<AdapterRule> rules;

  factory AdapterRuleListResult.fromMap(Map<String, dynamic> map) {
    final dynamic rawRules = map['rules'];
    return AdapterRuleListResult(
      version: map['version'] as String? ?? 'unknown',
      rules: rawRules is List<dynamic>
          ? rawRules
              .whereType<Map<String, dynamic>>()
              .map(AdapterRule.fromMap)
              .toList(growable: false)
          : const <AdapterRule>[],
    );
  }
}

class AdapterRule {
  AdapterRule({
    required this.adapterId,
    required this.name,
    required this.scriptUrl,
    required this.delaySeconds,
    required this.needsLogin,
    required this.hostIncludes,
    required this.pathIncludes,
  });

  final String adapterId;
  final String name;
  final String scriptUrl;
  final int delaySeconds;
  final bool needsLogin;
  final List<String> hostIncludes;
  final List<String> pathIncludes;

  factory AdapterRule.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> match = (map['match'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> extract = (map['extract'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return AdapterRule(
      adapterId: map['adapterId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      scriptUrl: extract['scriptUrl'] as String? ?? '',
      delaySeconds: extract['delaySeconds'] as int? ?? 0,
      needsLogin: extract['needsLogin'] as bool? ?? true,
      hostIncludes: (match['hostIncludes'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      pathIncludes: (match['pathIncludes'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}
