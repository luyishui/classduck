import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 旧版导入抓取页。
///
/// 该页面保留给旧链路使用：用户在独立 WebView 页面登录教务后，点击“完成登录”
/// 抓取当前 HTML 并返回给上层解析。Web 平台无法满足抓取要求，因此直接展示降级说明。
class ImportWebviewCaptureResult {
  ImportWebviewCaptureResult({
    required this.html,
    required this.pageUrl,
  });

  final String html;
  final String pageUrl;
}

class ImportWebviewCapturePage extends StatefulWidget {
  const ImportWebviewCapturePage({
    super.key,
    required this.initialUrl,
    required this.title,
  });

  final String initialUrl;
  final String title;

  @override
  State<ImportWebviewCapturePage> createState() => _ImportWebviewCapturePageState();
}

class _ImportWebviewCapturePageState extends State<ImportWebviewCapturePage> {
  WebViewController? _controller;
  bool _loading = true;
  bool _capturing = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    if (kIsWeb) {
      _loading = false;
      return;
    }

    final WebViewController controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _loading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _loading = false;
              _currentUrl = url;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            setState(() {
              _currentUrl = request.url;
            });
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
      _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登录并抓取 - ${widget.title}'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: _loading || _controller == null ? null : () => _controller!.reload(),
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: _capturing ? null : _captureCurrentHtml,
            child: Text(
              _capturing ? '抓取中...' : '完成登录',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          if (kIsWeb)
            _buildWebFallback()
          else if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  Future<void> _captureCurrentHtml() async {
    if (kIsWeb || _controller == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Web 端不支持内嵌抓取，请改用桌面端或移动端。')),
      );
      return;
    }

    setState(() {
      _capturing = true;
    });

    try {
      final Object rawHtml = await _controller!.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      );
      final Object rawUrl = await _controller!.runJavaScriptReturningResult(
        'window.location.href',
      );

      final String html = _normalizeJsResult(rawHtml);
      final String url = _normalizeJsResult(rawUrl);

      if (!mounted) {
        return;
      }

      if (html.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未获取到页面内容，请确认页面已加载完成。')),
        );
        return;
      }

      Navigator.of(context).pop(
        ImportWebviewCaptureResult(
          html: html,
          pageUrl: url.isEmpty ? _currentUrl : url,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('抓取失败，请确认已登录并进入课表页后重试。')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  String _normalizeJsResult(Object value) {
    final String raw = value.toString();
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is String) {
        return decoded;
      }
    } catch (_) {
      // Some platforms already return plain string.
    }
    return raw;
  }

  Widget _buildWebFallback() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Web 端无法在跨域教务页面中执行脚本注入和 HTML 抓取。\n'
          '请使用 Windows、Android 或 iOS 客户端完成导入。',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
