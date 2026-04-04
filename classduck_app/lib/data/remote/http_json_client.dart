import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/config/app_env.dart';
import 'api_exception.dart';

/// 统一的 JSON HTTP 客户端。
///
/// 当前项目的前后端契约较简单，绝大部分接口都返回 JSON object。
/// 这里集中处理 baseUrl 拼接、状态码校验和 JSON object 反序列化，
/// 避免每个 repository/service 重复写样板代码。
class HttpJsonClient {
  HttpJsonClient({http.Client? client, Duration? requestTimeout})
    : _client = client ?? http.Client(),
      _requestTimeout = requestTimeout ?? const Duration(seconds: 6);

  final http.Client _client;
  final Duration _requestTimeout;

  /// 发起 GET 请求，并约束响应必须是 JSON object。
  Future<Map<String, dynamic>> getJsonMap(String path) async {
    final Uri uri = Uri.parse('${AppEnv.apiBaseUrl}$path');
    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException('GET $path timeout after ${_requestTimeout.inSeconds}s');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('GET $path failed: ${response.statusCode}');
    }

    final dynamic data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw ApiException('GET $path returned non-object JSON payload');
    }

    return data;
  }

  /// 发起 JSON POST 请求，并约束响应必须是 JSON object。
  Future<Map<String, dynamic>> postJsonMap(
    String path, {
    required Map<String, Object?> body,
  }) async {
    final Uri uri = Uri.parse('${AppEnv.apiBaseUrl}$path');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'POST $path timeout after ${_requestTimeout.inSeconds}s',
      );
    }

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
