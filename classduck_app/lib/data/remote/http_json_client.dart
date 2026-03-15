import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/config/app_env.dart';
import 'api_exception.dart';

class HttpJsonClient {
  HttpJsonClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> getJsonMap(String path) async {
    final Uri uri = Uri.parse('${AppEnv.apiBaseUrl}$path');
    final http.Response response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('GET $path failed: ${response.statusCode}');
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw ApiException('GET $path returned non-object JSON payload');
    }

    return data;
  }

  Future<Map<String, dynamic>> postJsonMap(
    String path, {
    required Map<String, Object?> body,
  }) async {
    final Uri uri = Uri.parse('${AppEnv.apiBaseUrl}$path');
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('POST $path failed: ${response.statusCode}');
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw ApiException('POST $path returned non-object JSON payload');
    }

    return data;
  }
}
