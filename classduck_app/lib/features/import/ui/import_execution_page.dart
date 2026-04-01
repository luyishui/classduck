import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../schedule/data/schedule_repository.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/widgets/duck_pressable.dart';
import '../../../shared/navigation/duck_page_route.dart';
import '../application/import_engine.dart';
import '../data/import_api_service.dart';
import '../domain/school_config.dart';
import 'doubao_import_page.dart';

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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTokens.duckYellowSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('🌐', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Web 端不支持内嵌教务网页',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTokens.textMain),
            ),
            const SizedBox(height: 12),
            Text(
              '课表导入需要在 WebView 中登录教务系统\n'
              '并抓取页面数据，仅支持客户端使用。\n\n'
              '你可以点击下方按钮在浏览器中打开教务网站。',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTokens.textMuted, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            DuckPressable(
              borderRadius: BorderRadius.circular(AppTokens.radius24),
              onTap: onOpen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTokens.duckYellow,
                  borderRadius: BorderRadius.circular(AppTokens.radius24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTokens.duckYellow.withAlpha(50),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('在浏览器中打开', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius24)),
      backgroundColor: Colors.white,
      title: const Row(
        children: <Widget>[
          Text('⚠️', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('导入冲突处理', style: TextStyle(fontWeight: FontWeight.w700, color: AppTokens.textMain)),
        ],
      ),
      content: const Text(
        '检测到当前已有课表，请选择导入方式：',
        style: TextStyle(fontSize: 14, color: AppTokens.textMain),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(ImportConflictMode.createNew),
          child: const Text('新建课表导入', style: TextStyle(color: AppTokens.duckYellow, fontWeight: FontWeight.w600)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ImportConflictMode.overwriteExisting),
          child: Text('覆盖当前课表', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
        ),
      ],
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
    if (kIsWeb) {
      _webViewLoading = false;
      return;
    }

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
              LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: AppTokens.duckYellowSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTokens.duckYellow),
              ),
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
      decoration: BoxDecoration(
        color: AppTokens.pageBackground,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: <Widget>[
          // 返回
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppTokens.textMain,
            onPressed: () => Navigator.of(context).pop(),
          ),
          // URL 输入框
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTokens.radius20),
                border: Border.all(color: AppTokens.duckYellowSoft, width: 1.5),
              ),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 12),
                  Icon(Icons.language_rounded, size: 16, color: AppTokens.textMuted.withAlpha(140)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(fontSize: 13, color: AppTokens.textMain),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '输入教务网址…',
                        hintStyle: TextStyle(fontSize: 13, color: AppTokens.textMuted.withAlpha(140)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _navigateToUrl,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // ✓ 确认按钮（导航到输入的 URL）
          DuckPressable(
            borderRadius: BorderRadius.circular(AppTokens.radius20),
            onTap: () => _navigateToUrl(_urlController.text),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTokens.duckYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// 底部工具栏：电脑模式 + 密码帮助
  Widget _buildBottomToolbar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          _ToolbarPill(
            icon: Icons.auto_awesome_rounded,
            label: '豆包导入',
            active: false,
            onTap: _openDoubaoImport,
          ),
          const SizedBox(width: 10),
          _ToolbarPill(
            icon: Icons.desktop_windows_rounded,
            label: '电脑模式',
            active: _desktopMode,
            onTap: _toggleDesktopMode,
          ),
          const SizedBox(width: 10),
          _ToolbarPill(
            icon: Icons.help_outline_rounded,
            label: '密码一直错误？',
            active: false,
            onTap: _showPasswordHelp,
          ),
        ],
      ),
    );
  }

  Future<void> _openDoubaoImport() async {
    final String sourceLabel = widget.config.title.trim().isEmpty
        ? '当前教务系统'
        : widget.config.title.trim();
    final bool? imported = await Navigator.of(context).push<bool>(
      DuckPageRoute<bool>(
        builder: (BuildContext context) => DoubaoImportPage(
          sourceLabel: sourceLabel,
        ),
      ),
    );

    if (imported == true && mounted) {
      Navigator.of(context).pop(true);
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: <Widget>[
            Text('🔑', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('密码一直错误？', style: TextStyle(fontWeight: FontWeight.w700, color: AppTokens.textMain)),
          ],
        ),
        content: const Text(
          '1. 确认是否使用了正确的教务账号密码\n'
          '2. 部分学校初始密码为身份证后 6 位\n'
          '3. 如忘记密码，请联系学校教务处重置\n'
          '4. 部分学校需要连接校园网才能访问',
          style: TextStyle(fontSize: 14, color: AppTokens.textMain, height: 1.6),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道啦', style: TextStyle(color: AppTokens.duckYellow, fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: <Widget>[
            Text('📝', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('操作指南', style: TextStyle(fontWeight: FontWeight.w700, color: AppTokens.textMain)),
          ],
        ),
        content: const Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 14, color: AppTokens.textMain, height: 1.7),
            children: <TextSpan>[
              TextSpan(text: '1. 在上方输入教务网址，部分学校需连接校园网。\n\n'),
              TextSpan(text: '2. 登录后点击到'),
              TextSpan(
                text: '「个人课表」',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE85D5D)),
              ),
              TextSpan(text: '的页面，注意选择需要导入的学期，'),
              TextSpan(
                text: '首页课表通常不可导入！',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE85D5D)),
              ),
              TextSpan(text: '\n\n3. 点击右下角下载按钮完成导入。\n\n'),
              TextSpan(text: '4. 遇到网页错位，可尝试切换「电脑模式」。'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('如何正确选择教务？', style: TextStyle(color: AppTokens.textMuted, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道啦', style: TextStyle(color: AppTokens.duckYellow, fontWeight: FontWeight.w600)),
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
        builder: (BuildContext context) => const ImportConflictDialog(),
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
      await _apiService.reportLog(
        schoolId: widget.config.id,
        status: 'failed',
        errorMessage: _sanitizeForLog(error.toString()),
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

  Future<void> _tryCaptureRawJsonFromProviderScript() async {
    if (_webController == null) {
      return;
    }

    try {
      final Map<String, dynamic> schoolConfig = await _apiService.getSchoolConfig(widget.config.id);
      final Map<String, String> tokens = inferImportTermTokens(
        (schoolConfig['term_mapping'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );
      String script = await _apiService.getProviderScriptWithFallback(widget.config);
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

/// 右下角圆形浮动按钮（Macaron 风格）
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
    return DuckPressable(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: highlighted
              ? (onTap == null ? const Color(0xFFEDDFC0) : AppTokens.duckYellow)
              : Colors.white,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: highlighted
                  ? AppTokens.duckYellow.withAlpha(50)
                  : Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: highlighted ? Colors.white : AppTokens.textMuted,
        ),
      ),
    );
  }
}

/// 底部工具栏药丸按钮
class _ToolbarPill extends StatelessWidget {
  const _ToolbarPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuckPressable(
      borderRadius: BorderRadius.circular(AppTokens.radius20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTokens.duckYellowSoft : AppTokens.pageBackground,
          borderRadius: BorderRadius.circular(AppTokens.radius20),
          border: Border.all(
            color: active ? AppTokens.duckYellow : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: active ? AppTokens.duckYellow : AppTokens.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppTokens.duckYellow : AppTokens.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
