import '../../../data/remote/http_json_client.dart';

/// 兼容旧版 `/v1/import/logs` 契约的日志仓库。
///
/// 当前失败日志仍走旧接口，是因为现有 Flutter 页面和后端都保留了这条
/// 兼容链路。成功日志则走新的 `/api/import/log`，两者并存属于过渡阶段。
class ImportLogRepository {
  ImportLogRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  /// 上报一次导入失败，并返回后端确认后的 traceId。
  Future<String> reportImportFailure({
    required String schoolId,
    required String errorCode,
    required String message,
    required String appVersion,
    required String platform,
  }) async {
    final String traceId = _createTraceId();

    final Map<String, dynamic> response = await _client.postJsonMap(
      '/v1/import/logs',
      body: <String, Object?>{
        'traceId': traceId,
        'schoolId': schoolId,
        'errorCode': errorCode,
        'message': message,
        'appVersion': appVersion,
        'platform': platform,
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    return response['traceId'] as String? ?? traceId;
  }

  /// 生成轻量 traceId，便于排查前后端链路日志。
  String _createTraceId() {
    final int ms = DateTime.now().millisecondsSinceEpoch;
    return 'flutter-$ms';
  }
}
