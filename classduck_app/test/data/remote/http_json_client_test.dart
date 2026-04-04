import 'dart:convert';

import 'package:classduck_app/data/remote/api_exception.dart';
import 'package:classduck_app/data/remote/http_json_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpJsonClient', () {
    test('returns json object for GET response', () async {
      final HttpJsonClient client = HttpJsonClient(
        client: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'data': <String, dynamic>{'ok': true},
            }),
            200,
          );
        }),
      );

      final Map<String, dynamic> payload = await client.getJsonMap('/health');
      expect(payload['data'], isA<Map<String, dynamic>>());
    });

    test('throws ApiException on non-2xx response', () async {
      final HttpJsonClient client = HttpJsonClient(
        client: MockClient((http.Request request) async {
          return http.Response('{"message":"bad"}', 500);
        }),
      );

      expect(
        () => client.getJsonMap('/v1/config/schools'),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException when response is not a JSON object', () async {
      final HttpJsonClient client = HttpJsonClient(
        client: MockClient((http.Request request) async {
          return http.Response(jsonEncode(<String>['a', 'b']), 200);
        }),
      );

      expect(
        () => client.getJsonMap('/v1/config/schools'),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException when GET request times out', () async {
      final HttpJsonClient client = HttpJsonClient(
        client: MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          return http.Response('{"ok":true}', 200);
        }),
        requestTimeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        () => client.getJsonMap('/v1/config/schools'),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            contains('timeout'),
          ),
        ),
      );
    });

    test('throws ApiException when POST request times out', () async {
      final HttpJsonClient client = HttpJsonClient(
        client: MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          return http.Response('{"ok":true}', 200);
        }),
        requestTimeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        () => client.postJsonMap(
          '/api/import/log',
          body: <String, Object?>{'status': 'success'},
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            contains('timeout'),
          ),
        ),
      );
    });
  });
}