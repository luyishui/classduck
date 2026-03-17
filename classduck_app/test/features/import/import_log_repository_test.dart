import 'dart:convert';

import 'package:classduck_app/data/remote/http_json_client.dart';
import 'package:classduck_app/features/import/data/import_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('reportImportFailure posts v1 payload and returns traceId', () async {
    final MockClient mockClient = MockClient((http.Request request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/import/logs');

      final Map<String, dynamic> body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['schoolId'], 'xjtu');
      expect(body['errorCode'], 'IMPORT_ENGINE_FAILED');
      expect(body['platform'], 'windows');
      expect(body['traceId'], isNotEmpty);

      return http.Response(
        jsonEncode(<String, dynamic>{
          'accepted': true,
          'traceId': 'server-trace-id',
        }),
        202,
      );
    });

    final ImportLogRepository repository = ImportLogRepository(
      client: HttpJsonClient(client: mockClient),
    );

    final String traceId = await repository.reportImportFailure(
      schoolId: 'xjtu',
      errorCode: 'IMPORT_ENGINE_FAILED',
      message: 'boom',
      appVersion: '1.0.0',
      platform: 'windows',
    );

    expect(traceId, 'server-trace-id');
  });
}