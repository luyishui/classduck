import 'package:flutter/foundation.dart';

import '../../../data/remote/http_json_client.dart';

/// 发布到 GitHub Pages 的静态 release 信息，经 jsDelivr CDN 加速。
const String kReleaseCheckUrl =
    'https://cdn.jsdelivr.net/gh/luyishui/classduck@main/docs/release.json';

/// 官方备用源（GitHub Pages 静态直连），在 CDN 节点波动或缓存延迟时代偿。
const String kReleaseCheckFallbackUrl =
    'https://luyishui.github.io/classduck/release.json';

class ReleaseRepository {
  ReleaseRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  Future<ReleaseCheckResult> checkRelease({
    required String currentVersion,
    required String platform,
  }) async {
    Map<String, dynamic>? payload;

    if (kDebugMode) {
      // 本地联调：先尝试请求本地后端。若本地服务未启动，平滑回退到线上配置，避免开发时更新功能假死。
      try {
        final String localUrl =
            '/v1/release/check?currentVersion=$currentVersion&platform=$platform';
        payload = await _client.getJsonMap(localUrl);
      } catch (_) {
        payload = null;
      }
    }

    if (payload == null) {
      // 发布版或本地服务不可用：请求静态 release.json。
      // 追加防缓存时间戳，杜绝 jsDelivr CDN 与本地 HTTP 强缓存。
      final int ts = DateTime.now().millisecondsSinceEpoch;
      try {
        payload = await _client.getJsonMap('$kReleaseCheckUrl?_t=$ts');
      } catch (_) {
        // 主 CDN 访问失败，自动平滑切换至官方静态备用源。
        payload = await _client.getJsonMap('$kReleaseCheckFallbackUrl?_t=$ts');
      }
    }

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
      hasNewVersion: isNewerVersion(latestVersion, currentVersion),
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
  static bool isNewerVersion(String remote, String local) {
    final List<int> rv = parseVersion(remote);
    final List<int> lv = parseVersion(local);
    final int len = rv.length > lv.length ? rv.length : lv.length;
    for (int i = 0; i < len; i++) {
      final int r = i < rv.length ? rv[i] : 0;
      final int l = i < lv.length ? lv[i] : 0;
      if (r != l) return r > l;
    }
    return false;
  }

  static List<int> parseVersion(String version) {
    final String core = version.replaceFirst('v', '').split('+').first;
    return core
        .split('.')
        .map((String e) => int.tryParse(e.trim()) ?? 0)
        .toList();
  }
}
