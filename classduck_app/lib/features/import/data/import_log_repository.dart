import '../../../data/remote/http_json_client.dart';

class ImportLogRepository {
  ImportLogRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

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

  String _createTraceId() {
    final int ms = DateTime.now().millisecondsSinceEpoch;
    return 'flutter-$ms';
  }
}
