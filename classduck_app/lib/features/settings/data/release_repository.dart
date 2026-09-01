import 'package:flutter/foundation.dart';

import '../../../data/remote/http_json_client.dart';

/// 发布到 GitHub Pages 的静态 release 信息，经 jsDelivr CDN 加速。
const String kReleaseCheckUrl =
    'https://cdn.jsdelivr.net/gh/luyishui/classduck@main/docs/release.json';

class ReleaseRepository {
  ReleaseRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  Future<ReleaseCheckResult> checkRelease({
    required String currentVersion,
    required String platform,
  }) async {
    final String checkUrl;
    if (kDebugMode) {
      // 本地联调：继续请求本地后端。
      checkUrl =
          '/v1/release/check?currentVersion=$currentVersion&platform=$platform';
    } else {
      // 发布版：请求 GitHub Pages 上的静态 release.json（经 jsDelivr CDN）。
      checkUrl = kReleaseCheckUrl;
    }

    final Map<String, dynamic> payload = await _client.getJsonMap(checkUrl);
    // 兼容两种返回形状：后端包一层 data，静态 release.json 直接是字段。
    final dynamic data = payload['data'];
    final Map<String, dynamic> result =
        data is Map<String, dynamic> ? data : payload;

    return ReleaseCheckResult.fromMap(result);
  }
}

class ReleaseCheckResult {
  ReleaseCheckResult({
    required this.hasNewVersion,
    required this.latestVersion,
    required this.currentVersion,
    required this.updateUrl,
    required this.releaseNotes,
  });

  final bool hasNewVersion;
  final String latestVersion;
  final String currentVersion;
  final String updateUrl;
  final String releaseNotes;

  factory ReleaseCheckResult.fromMap(Map<String, dynamic> map) {
    final dynamic notes = map['releaseNotes'];
    return ReleaseCheckResult(
      hasNewVersion: map['hasNewVersion'] as bool? ?? false,
      latestVersion: map['latestVersion'] as String? ?? '1.0.0',
      currentVersion: map['currentVersion'] as String? ?? '1.0.0',
      updateUrl: map['updateUrl'] as String? ?? '',
      // releaseNotes 可能是数组（release.json）或字符串（后端），统一转字符串。
      releaseNotes: notes is List
          ? notes.map((dynamic e) => e.toString()).join('\n')
          : notes as String? ?? '',
    );
  }
}
