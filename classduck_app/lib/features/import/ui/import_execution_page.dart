import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../schedule/data/schedule_repository.dart';
import '../../../shared/theme/app_tokens.dart';
import '../application/import_engine.dart';
import '../data/import_api_service.dart';
import '../data/import_log_repository.dart';
import '../domain/school_config.dart';

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
/// ├─────────────────────────────────────┤
/// │  [电脑模式]    [密码一直错误？]       │  ← 底部工具栏
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

class _ImportExecutionPageState extends State<ImportExecutionPage> {
  final ImportEngine _importEngine = ImportEngine();
  final ImportLogRepository _logRepository = ImportLogRepository();
  final ImportApiService _apiService = ImportApiService();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();

  late final TextEditingController _urlController;

  // WebView 控制器（Web 端通过 webview_flutter_web 使用 iframe 实现）
  WebViewController? _webController;
  bool _webViewLoading = true;
  String _currentUrl = '';

  // 是否启用桌面模式（修改 User-Agent 为桌面浏览器）——仅原生端有效
  bool _desktopMode = false;

  // 导入相关状态
  bool _importing = false;
  String? _capturedHtml;
  String? _capturedUrl;

  // JS 注入路径数据：WebView 中 JS 脚本回传的原始课表 JSON
  String? _rawJsonFromJs;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.config.initialUrl;
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
    if (kIsWeb) return;

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.config.initialUrl));

    controller.setNavigationDelegate(
      NavigationDelegate(
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
      ),
    );

    _webController = controller;
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
                  // ── 右下角浮动按钮 ──
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _FloatingActionBtn(
                          icon: Icons.help_outline,
                          onTap: _showNoticeDialog,
                        ),
                        const SizedBox(height: 10),
                        _FloatingActionBtn(
                          icon: _importing
                              ? Icons.hourglass_top
                              : Icons.download,
                          onTap: _importing ? null : _captureAndImport,
                          highlighted: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── 底部工具栏 ──
            _buildBottomToolbar(context),
          ],
        ),
      ),
    );
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

  /// 底部工具栏：电脑模式 + 密码帮助
  Widget _buildBottomToolbar(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          OutlinedButton(
            onPressed: _toggleDesktopMode,
            style: OutlinedButton.styleFrom(
              backgroundColor: _desktopMode
                  ? AppTokens.duckYellow.withAlpha(40)
                  : null,
              side: BorderSide(
                color: _desktopMode
                    ? AppTokens.duckYellow
                    : Colors.grey.shade400,
              ),
            ),
            child: Text(
              '电脑模式',
              style: TextStyle(
                color: _desktopMode ? AppTokens.duckYellow : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _showPasswordHelp,
            child: const Text(
              '密码一直错误？',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Web 端替代 UI：提示用户使用桌面/移动客户端，并提供浏览器打开链接
  Widget _buildWebFallback() {
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
              onPressed: () => _openInBrowser(_currentUrl),
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

  /// 在外部浏览器中打开 URL
  Future<void> _openInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ════════════════════════════════════════════
  //  操作方法
  // ════════════════════════════════════════════

  /// 导航到用户输入的 URL
  void _navigateToUrl(String url) {
    final String trimmed = url.trim();
    if (trimmed.isEmpty) return;

    String finalUrl = trimmed;
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }

    if (kIsWeb) {
      // Web 端：在浏览器新标签页打开
      setState(() { _currentUrl = finalUrl; });
      _openInBrowser(finalUrl);
    } else {
      _webController?.loadRequest(Uri.parse(finalUrl));
    }
  }

  /// 切换电脑模式（修改 User-Agent）——仅原生端支持
  void _toggleDesktopMode() {
    setState(() {
      _desktopMode = !_desktopMode;
    });

    // Web 端 iframe 不支持 setUserAgent，跳过
    if (kIsWeb) return;

    // 设置桌面/移动 User-Agent 并重新加载
    if (_desktopMode) {
      _webController?.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );
    } else {
      _webController?.setUserAgent(null); // 恢复默认
    }

    _webController?.reload();
  }

  /// 密码帮助
  void _showPasswordHelp() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('密码一直错误？'),
        content: const Text(
          '1. 确认是否使用了正确的教务系统账号密码\n'
          '2. 部分学校初始密码为身份证后6位\n'
          '3. 如忘记密码，请联系学校教务处重置\n'
          '4. 部分学校需要连接校园网才能访问',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道啦'),
          ),
        ],
      ),
    );
  }

  /// 首次进入的注意事项对话框
  void _showNoticeDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('注意事项'),
        content: const Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(text: '1. 在上方输入教务网址，部分学校需要连接校园网。\n\n'),
              TextSpan(text: '2. 登录后点击到'),
              TextSpan(
                text: '个人课表',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              TextSpan(text: '的页面，注意选择自己需要导入的学期，'),
              TextSpan(
                text: '一般首页的课表都是不可导入的！',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              TextSpan(text: ' 另外不会导入调课、'),
              TextSpan(
                text: '停课的信息',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              TextSpan(text: '，请导入后自行修改！\n\n'),
              TextSpan(text: '3. 点击右下角的按钮完成导入。\n\n'),
              TextSpan(text: '4. 如果遇到网页错位等问题，可以尝试取消底栏的「电脑模式」或者调节字体缩放。'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('如何正确选择教务？'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道啦'),
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
    if (_webController == null) return;

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

    setState(() {
      _importing = true;
    });

    try {
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
  /// 3. hasRawJson → 后端校验通路；否则 → Dart 本地 HTML 解析。
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
        builder: (BuildContext context) => AlertDialog(
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
        ),
      );

      if (selected == null) {
        setState(() { _importing = false; });
        return;
      }
      mode = selected;
    }

    try {
      ImportExecutionResult result;

      if (hasRawJson) {
        // 新通路：JS 拿到的 raw JSON → 后端校验 → 存入本地
        result = await _importEngine.importFromRawJson(
          widget.config, rawJson: _rawJsonFromJs!, mode: mode,
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
      await _logRepository.reportImportFailure(
        schoolId: widget.config.id,
        errorCode: 'IMPORT_ENGINE_FAILED',
        message: _sanitizeForLog(error.toString()),
        appVersion: '0.1.0',
        platform: 'android',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '导入失败: ${error.toString().length > 80 ? '${error.toString().substring(0, 80)}...' : error}',
          ),
        ),
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
}

/// 右下角圆形浮动按钮
class _FloatingActionBtn extends StatelessWidget {
  const _FloatingActionBtn({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: highlighted
              ? (onTap == null ? const Color(0xFFEDDFC0) : AppTokens.duckYellow)
              : Colors.white.withAlpha(230),
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: highlighted ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }
}
