import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../schedule/data/schedule_repository.dart';
import '../../../shared/theme/app_tokens.dart';
import '../application/import_engine.dart';
import '../data/import_api_service.dart';
import '../data/import_log_repository.dart';
import '../domain/school_config.dart';
import 'import_webview_capture_page.dart';

class ImportExecutionPage extends StatefulWidget {
  const ImportExecutionPage({super.key, required this.config});

  final SchoolConfig config;

  @override
  State<ImportExecutionPage> createState() => _ImportExecutionPageState();
}

class _ImportExecutionPageState extends State<ImportExecutionPage> {
  final ImportEngine _importEngine = ImportEngine();
  final ImportLogRepository _logRepository = ImportLogRepository();
  final ImportApiService _apiService = ImportApiService();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  late final TextEditingController _loginUrlController;

  bool _importing = false;
  String? _result;
  String? _error;
  String? _capturedHtml;
  String? _capturedUrl;
  DateTime? _capturedAt;

  // JS 注入路径数据：当 WebView 中 JS 脚本通过 callHandler 回传原始课表 JSON 时，
  // 存入此字段。_runImport() 会优先检查此字段，有值走后端校验通路，否则走旧 HTML 解析。
  String? _rawJsonFromJs;

  @override
  void initState() {
    super.initState();
    _loginUrlController = TextEditingController(text: widget.config.initialUrl);
  }

  @override
  void dispose() {
    _loginUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('教务导入执行')),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: const EdgeInsets.all(AppTokens.space16),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(widget.config.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppTokens.space8),
                      Text('schoolId: ${widget.config.id}'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _loginUrlController,
                        decoration: const InputDecoration(
                          labelText: '登录页URL（可手动修改）',
                          hintText: '请输入教务登录页地址',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _openInAppLoginAndCapture,
                        icon: const Icon(Icons.language),
                        label: const Text('进入内嵌登录并抓取'),
                      ),
                      const SizedBox(height: 6),
                      Text('initialUrl: ${widget.config.initialUrl}'),
                      Text('targetUrl: ${widget.config.targetUrl}'),
                      Text('script: ${widget.config.extractScriptUrl}'),
                      const SizedBox(height: 8),
                      Text(
                        _capturedAt == null
                            ? '抓取状态：尚未抓取'
                            : '抓取状态：已抓取 (${_capturedAt!.toLocal().toString().substring(0, 19)})',
                        style: TextStyle(
                          color: _capturedAt == null ? AppTokens.textMuted : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_capturedUrl != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          '抓取页URL: $_capturedUrl',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('导入执行', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppTokens.space8),
                      const Text(
                        '请先点击“进入内嵌登录并抓取”，在应用内登录教务并进入课表页，点击右上角“完成登录”抓取页面。\n'
                        '抓取成功后，点击右下黄色下载按钮执行导入。',
                      ),
                      if (_result != null) ...<Widget>[
                        const SizedBox(height: AppTokens.space8),
                        Text('Result: $_result'),
                      ],
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: AppTokens.space8),
                        Text('Upload failed: $_error'),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 108,
            child: Column(
              children: <Widget>[
                _ExecToolButton(
                  icon: _importing ? Icons.hourglass_top : Icons.download,
                  onTap: _importing ? null : _runImport,
                ),
                const SizedBox(height: 10),
                _ExecToolButton(
                  icon: Icons.question_mark,
                  onTap: _showHelp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInAppLoginAndCapture() async {
    final String url = _loginUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入登录页URL。')),
      );
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web端暂不支持内嵌教务登录。你可以先修改URL，随后在 Android/iOS 上点此按钮抓取。')),
      );
      return;
    }

    final ImportWebviewCaptureResult? result = await Navigator.of(context).push<ImportWebviewCaptureResult>(
      MaterialPageRoute<ImportWebviewCaptureResult>(
        builder: (BuildContext context) => ImportWebviewCapturePage(
          initialUrl: url,
          title: widget.config.title,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _capturedHtml = result.html;
      _capturedUrl = result.pageUrl;
      _capturedAt = DateTime.now();
      _rawJsonFromJs = null;
      _error = null;
    });
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('导入帮助'),
          content: Text('1. 打开登录页并登录教务\n2. 进入课表页\n3. 点击右下黄色下载按钮导入'),
        );
      },
    );
  }

  /// 执行导入的核心方法——支持双通路自动选择。
  ///
  /// 【实现思路】
  /// 1. 检查是否有抓取数据（HTML 或 rawJson），无则提示用户先抓取。
  /// 2. 若已有课表，弹出冲突决策对话框（新建 or 覆盖）。
  /// 3. 根据 _rawJsonFromJs 是否有值选择通路：
  ///    - 有 rawJson → ImportEngine.importFromRawJson() → 后端校验
  ///    - 无 rawJson → ImportEngine.importFromCapturedHtml() → Dart 本地解析
  /// 4. 成功后通过 ImportApiService.reportLog() 上报成功日志。
  /// 5. 失败时通过旧 ImportLogRepository 上报错误日志（保留兼容）。
  Future<void> _runImport() async {
    final bool hasHtml = (_capturedHtml ?? '').trim().isNotEmpty;
    final bool hasRawJson = (_rawJsonFromJs ?? '').trim().isNotEmpty;

    if (!hasHtml && !hasRawJson) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先完成内嵌登录抓取，再执行导入。')),
      );
      return;
    }

    ImportConflictMode mode = ImportConflictMode.createNew;

    final int tableCount = (await _scheduleRepository.getCourseTables()).length;
    if (tableCount > 0) {
      if (!mounted) {
        return;
      }
      final ImportConflictMode? selected = await showDialog<ImportConflictMode>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('导入冲突处理'),
            content: const Text('检测到当前已有课表，选择导入方式：'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImportConflictMode.createNew),
                child: const Text('新建课表导入'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(ImportConflictMode.overwriteExisting),
                child: const Text('覆盖当前课表'),
              ),
            ],
          );
        },
      );

      if (selected == null) {
        return;
      }
      mode = selected;
    }

    setState(() {
      _importing = true;
      _error = null;
      _result = null;
    });

    try {
      ImportExecutionResult result;

      if (hasRawJson) {
        // 新通路：JS 拿到的 raw JSON → 后端校验 → 存入本地
        result = await _importEngine.importFromRawJson(
          widget.config,
          rawJson: _rawJsonFromJs!,
          mode: mode,
        );
      } else {
        // 旧通路：HTML 抓取 → Dart 本地解析 → 存入本地
        result = await _importEngine.importFromCapturedHtml(
          widget.config,
          html: _capturedHtml!,
          pageUrl: _capturedUrl ?? widget.config.initialUrl,
          mode: mode,
        );
      }

      setState(() {
        _result =
            '导入成功！共 ${result.importedCount} 门课程，课表: ${result.tableName}';
      });

      await _apiService.reportLog(
        schoolId: widget.config.id,
        status: 'success',
        courseCount: result.importedCount,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_result!)),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _error = error.toString();
      });

      await _logRepository.reportImportFailure(
        schoolId: widget.config.id,
        errorCode: 'IMPORT_ENGINE_FAILED',
        message: _sanitizeForLog(error.toString()),
        appVersion: '0.1.0',
        platform: 'android',
      );
    } finally {
      setState(() {
        _importing = false;
      });
    }
  }

  String _sanitizeForLog(String input) {
    final String noNewLines = input.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    String masked = noNewLines;

    masked = masked.replaceAll(
      RegExp(r'\b\d{8,20}\b'),
      '***',
    );
    masked = masked.replaceAll(
      RegExp(
        r'(token|session|cookie|authorization)\s*[:=]\s*[^\s;]+',
        caseSensitive: false,
      ),
      r'$1=***',
    );
    if (masked.length > 240) {
      masked = '${masked.substring(0, 240)}...';
    }
    return masked;
  }
}

class _ExecToolButton extends StatelessWidget {
  const _ExecToolButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFEDDFC0) : AppTokens.duckYellow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}
