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

    // 静态 release.json 没有计算能力，是否更新由客户端比对 latest 与本地版本。
    return ReleaseCheckResult.fromMap(result, localVersion: currentVersion);
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

  factory ReleaseCheckResult.fromMap(
    Map<String, dynamic> map, {
    String? localVersion,
  }) {
    final String latestVersion = map['latestVersion'] as String? ?? '0.0.0';
    final String currentVersion =
        localVersion ?? map['currentVersion'] as String? ?? '0.0.0';
    final dynamic notes = map['releaseNotes'];
    return ReleaseCheckResult(
      // 客户端语义化比对 latest 与本地版本；静态 release.json 的 hasNewVersion 不再可信。
      hasNewVersion: _isNewerVersion(latestVersion, currentVersion),
      latestVersion: latestVersion,
      currentVersion: currentVersion,
      updateUrl: map['updateUrl'] as String? ?? '',
      // releaseNotes 可能是数组（release.json）或字符串（后端），统一转字符串。
      releaseNotes: notes is List
          ? notes.map((dynamic e) => e.toString()).join('\n')
          : notes as String? ?? '',
    );
  }

  /// 语义化版本比较：remote > local 视为有新版本（忽略 v 前缀与构建号 +N）。
  static bool _isNewerVersion(String remote, String local) {
    final List<int> rv = _parseVersion(remote);
    final List<int> lv = _parseVersion(local);
    final int len = rv.length > lv.length ? rv.length : lv.length;
    for (int i = 0; i < len; i++) {
      final int r = i < rv.length ? rv[i] : 0;
      final int l = i < lv.length ? lv[i] : 0;
      if (r != l) return r > l;
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    final String core = version.replaceFirst('v', '').split('+').first;
    return core
        .split('.')
        .map((String e) => int.tryParse(e.trim()) ?? 0)
        .toList();
  }
}
