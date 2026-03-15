import '../../../data/remote/http_json_client.dart';

class ReleaseRepository {
  ReleaseRepository({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  Future<ReleaseCheckResult> checkRelease({
    required String currentVersion,
    required String platform,
  }) async {
    final Map<String, dynamic> payload = await _client.getJsonMap(
      '/v1/release/check?currentVersion=$currentVersion&platform=$platform',
    );
    final dynamic data = payload['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Release check response is invalid');
    }

    return ReleaseCheckResult.fromMap(data);
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
    return ReleaseCheckResult(
      hasNewVersion: map['hasNewVersion'] as bool? ?? false,
      latestVersion: map['latestVersion'] as String? ?? '1.0.0',
      currentVersion: map['currentVersion'] as String? ?? '1.0.0',
      updateUrl: map['updateUrl'] as String? ?? '',
      releaseNotes: map['releaseNotes'] as String? ?? '',
    );
  }
}
