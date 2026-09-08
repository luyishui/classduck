import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../data/remote/http_json_client.dart';

/// 全局当前应用版本号单一事实源（格式：vX.Y.Z）。
const String kCurrentAppVersion = 'v1.0.11';

/// 发布到 GitHub 的静态 release.json 多节点 CDN 与备用源池。
/// 按照在国内的解析与握手可靠性排序，平滑容灾。
const List<String> kReleaseCheckUrls = <String>[
  'https://testingcf.jsdelivr.net/gh/luyishui/classduck@main/docs/release.json',
  'https://fastly.jsdelivr.net/gh/luyishui/classduck@main/docs/release.json',
  'https://gcore.jsdelivr.net/gh/luyishui/classduck@main/docs/release.json',
  'https://cdn.jsdelivr.net/gh/luyishui/classduck@main/docs/release.json',
  'https://luyishui.github.io/classduck/release.json',
];

class ReleaseRepository {
  ReleaseRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  Future<ReleaseCheckResult> checkRelease({
    required String currentVersion,
    required String platform,
  }) async {
    Map<String, dynamic>? payload;

    if (kDebugMode) {
      // 本地联调：尝试请求本地后端。若本地服务未启动，1.5 秒内快速失败并回退到线上源。
      try {
        final String localUrl =
            '/v1/release/check?currentVersion=$currentVersion&platform=$platform';
        payload = await _client.getJsonMap(localUrl).timeout(
          const Duration(milliseconds: 1500),
        );
      } catch (_) {
        payload = null;
      }
    }

    if (payload == null) {
      // 遍历高可用多节点池：收集所有成功节点的返回，取版本号最高者裁决。
      // 各 CDN 节点缓存刷新不同步（如 jsDelivr 中国区节点无法被 purge），
      // 若以第一个有响应的节点为准，陈旧缓存会让用户误判为"已是最新"。
      final int ts = DateTime.now().millisecondsSinceEpoch;
      final List<Map<String, dynamic>> candidates = <Map<String, dynamic>>[];
      Object? lastError;

      for (final String baseUrl in kReleaseCheckUrls) {
        try {
          final String urlWithTs = '$baseUrl?_t=$ts';
          final Map<String, dynamic> raw = await _client
              .getJsonMap(urlWithTs)
              .timeout(
                const Duration(milliseconds: 3500),
              );
          if (raw.isEmpty) {
            continue;
          }
          // 兼容两种返回形状：后端包一层 data，静态 release.json 直接是字段。
          final dynamic data = raw['data'];
          final Map<String, dynamic> candidate =
              data is Map<String, dynamic> ? data : raw;
          candidates.add(candidate);

          // 任一节点返回的版本高于本地即可判定需要更新，无需再等其余节点。
          final String? candidateVersion = candidate['latestVersion'] as String?;
          if (candidateVersion != null &&
              ReleaseCheckResult.isNewerVersion(candidateVersion, currentVersion)) {
            payload = candidate;
            break;
          }
        } catch (e) {
          lastError = e;
          // 继续尝试下一个高可用源
        }
      }

      if (payload == null) {
        if (candidates.isEmpty) {
          throw lastError ?? Exception('无法连接到更新服务，所有备用节点均不可用');
        }
        // 没有任何节点比本地新：取返回版本号最高的节点作为裁决结果。
        payload = _highestVersionPayload(candidates);
      }
    }

    // 兼容两种返回形状：后端包一层 data，静态 release.json 直接是字段。
    final dynamic data = payload['data'];
    final Map<String, dynamic> result =
        data is Map<String, dynamic> ? data : payload;

    // 静态 release.json 没有计算能力，是否更新由客户端比对 latest 与本地版本。
    return ReleaseCheckResult.fromMap(result, localVersion: currentVersion);
  }

  /// 从多个候选节点数据中选出返回版本号最高的那份，让陈旧缓存节点被更新的节点压过。
  static Map<String, dynamic> _highestVersionPayload(
    List<Map<String, dynamic>> candidates,
  ) {
    Map<String, dynamic> best = candidates.first;
    for (final Map<String, dynamic> candidate in candidates.skip(1)) {
      final String? bestVersion = best['latestVersion'] as String?;
      final String? candidateVersion = candidate['latestVersion'] as String?;
      final bool candidateIsBetter = candidateVersion != null &&
          (bestVersion == null ||
              ReleaseCheckResult.isNewerVersion(candidateVersion, bestVersion));
      if (candidateIsBetter) {
        best = candidate;
      }
    }
    return best;
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
