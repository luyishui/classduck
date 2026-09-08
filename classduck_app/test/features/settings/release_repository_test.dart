import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:classduck_app/data/remote/http_json_client.dart';
import 'package:classduck_app/features/settings/data/release_repository.dart';

void main() {
  group('ReleaseCheckResult version comparison', () {
    test('isNewerVersion compares versions correctly', () {
      expect(ReleaseCheckResult.isNewerVersion('1.0.8', '1.0.7'), isTrue);
      expect(ReleaseCheckResult.isNewerVersion('v1.0.8', 'v1.0.7'), isTrue);
      expect(ReleaseCheckResult.isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(ReleaseCheckResult.isNewerVersion('2.0.0', '1.9.9'), isTrue);
      expect(ReleaseCheckResult.isNewerVersion('1.0.8+8', '1.0.7+7'), isTrue);

      expect(ReleaseCheckResult.isNewerVersion('1.0.8', '1.0.8'), isFalse);
      expect(ReleaseCheckResult.isNewerVersion('1.0.7', '1.0.8'), isFalse);
      expect(ReleaseCheckResult.isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('parseVersion splits dots and trims values safely', () {
      expect(ReleaseCheckResult.parseVersion('v1.0.8+8'), <int>[1, 0, 8]);
      expect(ReleaseCheckResult.parseVersion('1.2.3'), <int>[1, 2, 3]);
      expect(ReleaseCheckResult.parseVersion(''), <int>[0]);
    });

    test('ReleaseCheckResult fromMap handles arrays and strings for releaseNotes', () {
      final ReleaseCheckResult res = ReleaseCheckResult.fromMap(
        <String, dynamic>{
          'latestVersion': '1.0.9',
          'updateUrl': 'https://example.com',
          'releaseNotes': <String>['更新A', '更新B'],
        },
        localVersion: '1.0.8',
      );
      expect(res.hasNewVersion, isTrue);
      expect(res.releaseNotes, '更新A\n更新B');
    });
  });

  group('ReleaseRepository multi-node failover', () {
    test('fails over to next CDN node when first node fails', () async {
      int requestCount = 0;
      final MockClient mockHttp = MockClient((http.Request request) async {
        requestCount++;
        // 第一次请求模拟网络异常（如 DNS 污染或 500）
        if (requestCount == 1) {
          return http.Response('Internal Error', 500);
        }
        // 第二次请求成功返回
        return http.Response.bytes(
          utf8.encode(jsonEncode(<String, dynamic>{
            'latestVersion': '1.0.9',
            'updateUrl': 'https://luyishui.github.io/classduck/',
            'releaseNotes': <String>['修复问题'],
          })),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      });

      final HttpJsonClient client = HttpJsonClient(client: mockHttp);
      final ReleaseRepository repo = ReleaseRepository(client: client);

      final ReleaseCheckResult result = await repo.checkRelease(
        currentVersion: '1.0.8',
        platform: 'android',
      );

      expect(result.hasNewVersion, isTrue);
      expect(result.latestVersion, '1.0.9');
      expect(requestCount, greaterThanOrEqualTo(2));
    });

    test('throws when all nodes fail', () async {
      final MockClient mockHttp = MockClient((http.Request request) async {
        return http.Response('Down', 500);
      });

      final HttpJsonClient client = HttpJsonClient(client: mockHttp);
      final ReleaseRepository repo = ReleaseRepository(client: client);

      expect(
        () => repo.checkRelease(
          currentVersion: '1.0.8',
          platform: 'android',
        ),
        throwsA(anything),
      );
    });

    // 第 1 个请求是 kDebugMode 下的本地联调请求，让其失败以走线上节点池；
    // 之后按节点顺序：第 2 个返回陈旧的 1.0.9，第 3 个及以后返回 1.0.10。
    MockClient staleThenFreshMock() {
      int requestCount = 0;
      return MockClient((http.Request request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Internal Error', 500);
        }
        final String version = requestCount == 2 ? '1.0.9' : '1.0.10';
        return http.Response.bytes(
          utf8.encode(jsonEncode(<String, dynamic>{
            'latestVersion': version,
            'updateUrl': 'https://luyishui.github.io/classduck/',
            'releaseNotes': <String>['更新到 $version'],
          })),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      });
    }

    test('stale first CDN node does not mask a newer node', () async {
      final MockClient mockHttp = staleThenFreshMock();

      final HttpJsonClient client = HttpJsonClient(client: mockHttp);
      final ReleaseRepository repo = ReleaseRepository(client: client);

      // 手机上是 1.0.9：即使第一个节点仍返回陈旧的 1.0.9，
      // 后续节点返回 1.0.10 时也必须判定有新版本。
      final ReleaseCheckResult result = await repo.checkRelease(
        currentVersion: '1.0.9',
        platform: 'android',
      );

      expect(result.hasNewVersion, isTrue);
      expect(result.latestVersion, '1.0.10');
    });

    test('picks highest version when no node is newer than local', () async {
      final MockClient mockHttp = staleThenFreshMock();

      final HttpJsonClient client = HttpJsonClient(client: mockHttp);
      final ReleaseRepository repo = ReleaseRepository(client: client);

      // 本地已是 1.0.10：第一个陈旧节点（1.0.9）不应带偏结果，
      // 裁决应取到节点池中的最高版本 1.0.10，判定无更新。
      final ReleaseCheckResult result = await repo.checkRelease(
        currentVersion: '1.0.10',
        platform: 'android',
      );

      expect(result.hasNewVersion, isFalse);
      expect(result.latestVersion, '1.0.10');
    });
  });
}

