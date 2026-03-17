import 'dart:convert';

import 'package:classduck_app/data/remote/http_json_client.dart';
import 'package:classduck_app/features/import/data/import_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ImportApiService', () {
    test('validateImport posts expected payload', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/import/validate');

        final Map<String, dynamic> body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['school_id'], 'xjtu');
        expect(body['raw_data'], '[{"kcmc":"高等数学"}]');
        expect(body['year'], '2025');
        expect(body['term'], '1');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': true,
            'data': <String, dynamic>{'courses': <dynamic>[]},
          }),
          200,
        );
      });

      final ImportApiService service = ImportApiService(
        client: HttpJsonClient(client: mockClient),
      );

      final Map<String, dynamic> result = await service.validateImport(
        schoolId: 'xjtu',
        rawData: '[{"kcmc":"高等数学"}]',
        year: '2025',
        term: '1',
      );

      expect(result['success'], true);
    });

    test('reportLog swallows transport errors', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        throw Exception('network down');
      });

      final ImportApiService service = ImportApiService(
        client: HttpJsonClient(client: mockClient),
      );

      await service.reportLog(
        schoolId: 'xjtu',
        status: 'success',
        courseCount: 2,
      );
    });
  });
}