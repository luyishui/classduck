import 'dart:convert';

import 'package:classduck_app/data/remote/api_exception.dart';
import 'package:classduck_app/data/remote/http_json_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpJsonClient', () {
    test('throws ApiException on non-2xx response', () async {
      final client = HttpJsonClient(
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
      final client = HttpJsonClient(
        client: MockClient((http.Request request) async {
          return http.Response(jsonEncode(<String>['a', 'b']), 200);
        }),
      );

      expect(
        () => client.getJsonMap('/v1/config/schools'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}