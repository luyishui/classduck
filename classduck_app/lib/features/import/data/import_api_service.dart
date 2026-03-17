import '../../../data/remote/http_json_client.dart';

/// 对接 Python 导入后端 /api 系列接口的服务层。
///
/// 【设计思路】
/// 本类封装了 Flutter → Python 后端的全部 HTTP 调用，
/// 使用 HttpJsonClient 统一处理 baseUrl 拼接和 JSON 序列化。
///
/// 四个核心方法：
/// 1. getSchoolConfig  — 获取学校完整配置（field_mapping/timer_config 等）
/// 2. getProviderScript — 下载 JS 注入脚本（用于 WebView 内获取课表数据）
/// 3. validateImport    — 将原始 JSON 发到后端做字段映射 + 周次/节次解析
/// 4. reportLog         — 上报导入结果日志（成功或失败）
///
/// 日志上报 reportLog 失败时静默忽略——日志不应阻塞主流程。
class ImportApiService {
  ImportApiService({HttpJsonClient? client}) : _client = client ?? HttpJsonClient();

  final HttpJsonClient _client;

  /// 获取某学校的完整配置（含 field_mapping / timer_config 等）。
  Future<Map<String, dynamic>> getSchoolConfig(String schoolId) async {
    return _client.getJsonMap('/api/schools/$schoolId/config');
  }

  /// 下载指定学校的 JS 解析脚本。
  Future<String> getProviderScript(String schoolId, {String type = 'provider'}) async {
    final Map<String, dynamic> payload =
        await _client.getJsonMap('/api/schools/$schoolId/script?script_type=$type');
    return payload['script'] as String? ?? '';
  }

  /// 将 WebView 拿到的原始 JSON 发给后端校验并返回标准化结果。
  Future<Map<String, dynamic>> validateImport({
    required String schoolId,
    required String rawData,
    String year = '',
    String term = '',
  }) async {
    return _client.postJsonMap(
      '/api/import/validate',
      body: <String, Object?>{
        'school_id': schoolId,
        'raw_data': rawData,
        'year': year,
        'term': term,
      },
    );
  }

  /// 上报导入日志（成功或失败都可以报）。
  Future<void> reportLog({
    required String schoolId,
    required String status,
    String errorMessage = '',
    int courseCount = 0,
  }) async {
    try {
      await _client.postJsonMap(
        '/api/import/log',
        body: <String, Object?>{
          'school_id': schoolId,
          'status': status,
          'error_message': errorMessage,
          'course_count': courseCount,
        },
      );
    } catch (_) {
      // 日志上报失败不影响主流程。
    }
  }
}
