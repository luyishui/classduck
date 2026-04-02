import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../schedule/data/schedule_repository.dart';
import '../../../shared/theme/app_tokens.dart';
import '../application/import_engine.dart';
import '../data/import_api_service.dart';
import '../domain/school_config.dart';

String normalizeImportUrl(String url) {
  final String trimmed = url.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

Map<String, String> inferImportTermTokens(
  Map<String, dynamic> termMapping, {
  DateTime? now,
}) {
  final DateTime current = now ?? DateTime.now();
  final bool firstSemester = current.month >= 8 || current.month == 1;
  final String schoolYear = current.month >= 8
      ? current.year.toString()
      : (current.year - 1).toString();
  final String term = firstSemester
      ? (termMapping['first'] as String? ?? '1')
      : (termMapping['second'] as String? ?? '2');

  return <String, String>{
    'year': schoolYear,
    'term': term,
  };
}

/// 教务导入页面 —— 一体化 WebView 设计
///
/// 【设计思路】
/// 参考小爱课程表等主流课表 App 的导入 UX：
/// 选择学校后直接打开全屏 WebView 加载教务网站，用户在 WebView 内
/// 完成登录并导航到个人课表页后，点击右下角下载按钮触发 HTML 抓取 + 导入。
///
/// 页面结构：
/// ┌─────────────────────────────────────┐
/// │ ← │ URL 栏（可编辑）         │ ✓  │  ← 顶部导航栏
/// ├─────────────────────────────────────┤
/// │                                     │
/// │         全屏 WebView                │  ← 教务系统网页
/// │                                     │
/// └─────────────────────────────────────┘
///                                  [?]    ← 右下角浮动按钮
///                                  [↓]
///
/// 首次进入时弹出注意事项对话框，告知用户操作步骤。
class ImportExecutionPage extends StatefulWidget {
  const ImportExecutionPage({super.key, required this.config});

  final SchoolConfig config;

  @override
  State<ImportExecutionPage> createState() => _ImportExecutionPageState();
}

class ImportWebFallbackPanel extends StatelessWidget {
  const ImportWebFallbackPanel({
    super.key,
    required this.onOpen,
  });

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.web_asset_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Web 端不支持内嵌教务网页',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '课表导入需要在 WebView 中登录教务系统并抓取页面数据，\n'
              '该功能仅在 Windows / Android / iOS 客户端可用。\n\n'
              '你可以点击下方按钮在浏览器新标签页中打开教务网站。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('在浏览器中打开教务网站'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.duckYellow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImportConflictDialog extends StatelessWidget {
  const ImportConflictDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '课表导入冲突处理',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            '检测到您当前已存在课表数据，请选择本次导入的处理方式：',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(ImportConflictMode.createNew),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.duckYellow,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('新增为独立课表'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(ImportConflictMode.overwriteExisting),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTokens.duckYellow,
                      side: const BorderSide(color: AppTokens.duckYellow, width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('覆盖原有课表'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportExecutionPageState extends State<ImportExecutionPage> {
  final ImportEngine _importEngine = ImportEngine();
  final ImportApiService _apiService = ImportApiService();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();

  late final TextEditingController _urlController;

  // WebView 控制器（Web 端通过 webview_flutter_web 使用 iframe 实现）
  WebViewController? _webController;
  bool _webViewLoading = true;
  bool _cacheMissRecovering = false;
  bool _cacheMissRecoveredHintShown = false;
  String _currentUrl = '';

  // 导入相关状态
  bool _importing = false;
  String? _capturedHtml;
  String? _capturedUrl;

  // JS 注入路径数据：WebView 中 JS 脚本回传的原始课表 JSON
  String? _rawJsonFromJs;

  bool get _isGeneralPortal {
    final String id = widget.config.id.toLowerCase();
    final String title = widget.config.title;
    return id.contains('general') || title.contains('通用');
  }

  String _effectiveInitialUrl() {
    final String resolved = _resolveInitialUrl(widget.config).trim();
    if (resolved.isEmpty) {
      return 'about:blank';
    }
    return normalizeImportUrl(resolved);
  }

  @override
  void initState() {
    super.initState();
    _currentUrl = _effectiveInitialUrl();
    _urlController = TextEditingController(text: _currentUrl);

    _initWebView();

    // 首次进入弹出注意事项
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNoticeDialog();
    });
  }

  /// 初始化 WebView 控制器并加载学校登录页。
  /// Web 端不支持 WebView，跳过初始化；原生端使用系统 WebView。
  void _initWebView() {
    // Web 平台不支持 webview_flutter，跳过初始化
    if (kIsWeb) {
      _webViewLoading = false;
      return;
    }

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          final String url = request.url;
          if (url.startsWith('chrome-error://')) {
            _recoverFromCacheMiss();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (String url) {
          if (!mounted) return;
          setState(() {
            _webViewLoading = true;
            _currentUrl = url;
            _urlController.text = url;
          });
        },
        onPageFinished: (String url) {
          if (!mounted) return;
          setState(() {
            _webViewLoading = false;
            _currentUrl = url;
            _urlController.text = url;
          });
        },
        onWebResourceError: (WebResourceError error) {
          if (!mounted) {
            return;
          }

          setState(() {
            _webViewLoading = false;
          });

          final String desc = error.description.toLowerCase();
          if (!desc.contains('err_cache_miss')) {
            return;
          }
          _recoverFromCacheMiss();
        },
      ),
    );

    unawaited(_loadInitialLoginPage(controller));

    _webController = controller;
  }

  Future<void> _loadInitialLoginPage(WebViewController controller) async {
    try {
      await controller.clearCache();
    } catch (_) {
      // 某些设备上清缓存可能失败，失败时不阻塞后续加载。
    }
    await _loadUrlDirect(_effectiveInitialUrl(), controller: controller);
  }

  Future<void> _loadUrlDirect(String url, {WebViewController? controller}) async {
    final WebViewController? target = controller ?? _webController;
    if (target == null) {
      return;
    }

    final String normalized = normalizeImportUrl(url);
    if (normalized.isEmpty) {
      return;
    }

    await target.loadRequest(Uri.parse(normalized));
  }

  Future<void> _recoverFromCacheMiss() async {
    if (_cacheMissRecovering) {
      return;
    }
    _cacheMissRecovering = true;
    try {
      await _webController?.clearCache();
      await _webController?.clearLocalStorage();

      final String retryUrl = _buildCacheMissRecoveryUrl();
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _loadUrlDirect(retryUrl);

      if (mounted && !_cacheMissRecoveredHintShown) {
        _cacheMissRecoveredHintShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登录页缓存异常，已自动清理缓存并重试。')),
        );
      }
    } finally {
      _cacheMissRecovering = false;
    }
  }

  String _buildCacheMissRecoveryUrl() {
    final String base = _currentUrl.trim().isNotEmpty && _currentUrl != 'about:blank'
        ? _currentUrl
        : _effectiveInitialUrl();
    return normalizeImportUrl(base);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── 顶部 URL 导航栏 ──
            _buildUrlBar(context),
            // ── 加载进度条 ──
            if (_webViewLoading)
              const LinearProgressIndicator(minHeight: 2),
            // ── WebView 主体（原生端）/ 替代提示（Web 端）──
            Expanded(
              child: Stack(
                children: <Widget>[
                  if (kIsWeb)
                    _buildWebFallback()
                  else if (_webController != null)
                    WebViewWidget(controller: _webController!),
                  if (_isGeneralPortal && (_currentUrl == 'about:blank' || _currentUrl.isEmpty))
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(235),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE9DFC8)),
                        ),
                        child: const Text(
                          '请输入教务网址并填写账号密码，登录后点击下载按钮导入课表。',
                          style: TextStyle(fontSize: 12, color: Color(0xFF5B4D3D)),
                        ),
                      ),
                    ),
                  // ── 右下角浮动按钮 ──
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _FloatingActionBtn(
                          icon: _importing
                              ? Icons.hourglass_top
                              : Icons.download,
                          onTap: _importing ? null : _captureAndImport,
                        ),
                        const SizedBox(height: 20),
                        _FloatingActionBtn(
                          icon: Icons.question_mark,
                          onTap: _showNoticeDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveInitialUrl(SchoolConfig config) {
    final String id = config.id.toLowerCase();
    final String title = config.title;
    final bool isXjtu = id.contains('xjtu') || title.contains('西安交通大学');
    if (isXjtu) {
      return 'https://gmis.xjtu.edu.cn/pyxx/pygl/xskbcx';
    }
    return config.initialUrl;
  }

  /// 顶部 URL 栏：返回按钮 + 可编辑地址 + ✓ 确认导航
  Widget _buildUrlBar(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: <Widget>[
          // 返回
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // URL 输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '在此输入教务网址',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        TextField(
                          controller: _urlController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _navigateToUrl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ✓ 确认按钮（导航到输入的 URL）
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _navigateToUrl(_urlController.text),
          ),
        ],
      ),
    );
  }

  /// Web 端替代 UI：提示用户使用桌面/移动客户端，并提供浏览器打开链接
  Widget _buildWebFallback() {
    return ImportWebFallbackPanel(onOpen: () => _openInBrowser(_currentUrl));
  }

  /// 在外部浏览器中打开 URL
  Future<void> _openInBrowser(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前网址无效，请检查后重试。')),
      );
    }
  }

  // ════════════════════════════════════════════
  //  操作方法
  // ════════════════════════════════════════════

  /// 导航到用户输入的 URL
  void _navigateToUrl(String url) {
    final String finalUrl = normalizeImportUrl(url);
    if (finalUrl.isEmpty) return;

    if (kIsWeb) {
      // Web 端：在浏览器新标签页打开
      setState(() { _currentUrl = finalUrl; });
      _openInBrowser(finalUrl);
    } else {
      _loadUrlDirect(finalUrl);
    }
  }

  /// 首次进入的注意事项对话框
  void _showNoticeDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '操作注意事项',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '1. 请在页面上方输入对应教务系统的网址，部分院校需连接校园内网方可正常访问。',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '2. 登录成功后，请进入个人课表页面，选择需要导入的对应学期。',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTokens.duckYellowSoft,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  border: Border.fromBorderSide(
                    BorderSide(color: AppTokens.duckYellow, width: 1.2),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text(
                    '▶ 首页展示的课表通常无法直接导入；系统暂不支持自动导入调课、停课相关信息，导入完成后请您自行核对修改。',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6E4F00),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '3. 确认课表信息无误后，点击页面右下角按钮即可完成课表导入。',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '4. 若出现网页错位、显示异常等问题，可尝试调整页面字体缩放比例解决。',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTokens.duckYellow,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            child: const Text('我已了解'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  抓取与导入
  // ════════════════════════════════════════════

  /// 点击下载按钮：抓取当前页面 HTML 并执行导入。
  ///
  /// 【实现思路】
  /// 1. Web 端由于 iframe 跨域限制，无法执行 JS 抓取，提示使用桌面/移动端
  /// 2. 原生端从 WebView 抓取当前页面 HTML 和 URL
  /// 3. 若有 rawJsonFromJs（JS 脚本注入回传），走后端校验通路
  /// 4. 否则走旧 HTML 解析通路
  /// 5. 成功后上报日志并返回上一页
  Future<void> _captureAndImport() async {
    // Web 端 iframe 无法跨域执行 JS，提示降级
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Web 端暂不支持课表抓取，请使用 Windows / Android / iOS 客户端完成导入。'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_webController == null) return;

    setState(() {
      _importing = true;
    });

    try {
      _rawJsonFromJs = null;
      await _tryCaptureRawJsonFromProviderScript();

      // 先抓取当前 HTML
      final Object rawHtml = await _webController!.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      );
      final Object rawUrl = await _webController!.runJavaScriptReturningResult(
        'window.location.href',
      );

      _capturedHtml = _normalizeJsResult(rawHtml);
      _capturedUrl = _normalizeJsResult(rawUrl);
      if (_capturedUrl!.isEmpty) {
        _capturedUrl = _currentUrl;
      }

      // 执行导入
      await _runImport();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('抓取失败: $error')),
      );
      setState(() {
        _importing = false;
      });
    }
  }

  /// 执行导入的核心方法——支持双通路自动选择。
  ///
  /// 【实现思路】
  /// 1. 检查是否有抓取数据（HTML 或 rawJson），无则提示。
  /// 2. 若已有课表，弹出冲突决策对话框（新建 or 覆盖）。
  /// 3. 统一走后端校验通路（优先 rawJson，否则提交 HTML）。
  /// 4. 成功 → 上报日志 → 返回上一页。
  /// 5. 失败 → 上报错误日志 → SnackBar 提示。
  Future<void> _runImport() async {
    final bool hasHtml = (_capturedHtml ?? '').trim().isNotEmpty;
    final bool hasRawJson = (_rawJsonFromJs ?? '').trim().isNotEmpty;

    if (!hasHtml && !hasRawJson) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未获取到页面内容，请确认页面已加载完成。')),
      );
      setState(() { _importing = false; });
      return;
    }

    // 检查冲突
    ImportConflictMode mode = ImportConflictMode.createNew;
    final int tableCount = (await _scheduleRepository.getCourseTables()).length;
    if (tableCount > 0) {
      if (!mounted) return;
      final ImportConflictMode? selected = await showDialog<ImportConflictMode>(
        context: context,
        builder: (BuildContext context) => const ImportConflictDialog(),
      );

      if (selected == null) {
        setState(() { _importing = false; });
        return;
      }
      mode = selected;
    }

    try {
      final String payload = hasRawJson ? _rawJsonFromJs! : _capturedHtml!;
      final ImportExecutionResult result = await _importEngine.importFromRawJson(
        widget.config,
        rawJson: payload,
        mode: mode,
      );

      await _apiService.reportLog(
        schoolId: widget.config.id,
        status: 'success',
        courseCount: result.importedCount,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入成功！共 ${result.importedCount} 门课程')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      await _apiService.reportLog(
        schoolId: widget.config.id,
        status: 'failed',
        errorMessage: _sanitizeForLog(error.toString()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('系统维护中，请稍后再试')),
      );
    } finally {
      if (mounted) {
        setState(() { _importing = false; });
      }
    }
  }

  /// 将 WebView JS 执行结果规范化为 Dart 字符串。
  /// 有些平台返回 JSON 编码的字符串（带引号），有些返回裸字符串。
  String _normalizeJsResult(Object value) {
    final String raw = value.toString();
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is String) return decoded;
    } catch (_) {}
    return raw;
  }

  /// 日志脱敏：掩码学号/token 等敏感信息，截断过长内容。
  String _sanitizeForLog(String input) {
    String masked = input.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    masked = masked.replaceAll(RegExp(r'\b\d{8,20}\b'), '***');
    masked = masked.replaceAll(
      RegExp(
        r'(token|session|cookie|authorization)\s*[:=]\s*[^\s;]+',
        caseSensitive: false,
      ),
      r'$1=***',
    );
    if (masked.length > 240) masked = '${masked.substring(0, 240)}...';
    return masked;
  }

  Future<void> _tryCaptureRawJsonFromProviderScript() async {
    if (_webController == null) {
      return;
    }

    try {
      final Map<String, dynamic> schoolConfig = await _apiService.getSchoolConfig(widget.config.id);
      final Map<String, String> tokens = inferImportTermTokens(
        (schoolConfig['term_mapping'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );
      String script = await _apiService.getProviderScript(widget.config.id);
      if (script.trim().isEmpty) {
        return;
      }

      script = script
          .replaceAll('{{YEAR}}', tokens['year'] ?? '')
          .replaceAll('{{TERM}}', tokens['term'] ?? '')
          .replaceFirst('(async function()', 'await (async function()');

      final Object rawResult = await _webController!.runJavaScriptReturningResult(
        '''
        (async function() {
          let __classduckResult = null;
          window.flutter_inappwebview = {
            callHandler: function(_name, payload) {
              __classduckResult = payload;
              return Promise.resolve(payload);
            }
          };
          $script
          return __classduckResult;
        })()
        ''',
      );

      final String normalized = _normalizeJsResult(rawResult).trim();
      if (normalized.isEmpty || normalized == 'null') {
        return;
      }

      final dynamic decoded = jsonDecode(normalized);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      if (decoded['success'] != true) {
        return;
      }

      final dynamic data = decoded['data'];
      if (data == null) {
        return;
      }

      _rawJsonFromJs = jsonEncode(data);
    } catch (_) {
      // JS 注入失败时静默回退到 HTML 抓取路径，不阻塞旧链路。
    }
  }

}

/// 右下角圆形浮动按钮
class _FloatingActionBtn extends StatelessWidget {
  const _FloatingActionBtn({
    required this.icon,
    required this.onTap,
  });

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
        child: Icon(
          icon,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }
}
