import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../shared/theme/app_tokens.dart';

class SurveyWebviewPage extends StatefulWidget {
  const SurveyWebviewPage({
    super.key,
    required this.title,
    required this.url,
    this.shareUrl = '',
  });

  final String title;
  final String url;
  final String shareUrl;

  @override
  State<SurveyWebviewPage> createState() => _SurveyWebviewPageState();
}

class _SurveyWebviewPageState extends State<SurveyWebviewPage> {
  WebViewController? _controller;
  bool _loading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;

    if (kIsWeb) {
      _loading = false;
      return;
    }

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!mounted) {
              return;
            }
            setState(() {
              _loading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            if (!mounted) {
              return;
            }
            setState(() {
              _loading = false;
              _currentUrl = url;
            });
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted || error.isForMainFrame != true) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('页面加载失败：${error.description}')),
            );
          },
        ),
      );

    controller.loadRequest(Uri.parse(widget.url));
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTokens.textMain,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: '分享链接',
            onPressed: _showShareDialog,
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: kIsWeb
                ? _buildWebFallback()
                : (_controller == null
                      ? const SizedBox.shrink()
                      : WebViewWidget(controller: _controller!)),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '当前平台不支持内嵌问卷页面，可在浏览器继续填写。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTokens.textMuted, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _openInBrowser(widget.url),
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.duckYellow,
                foregroundColor: AppTokens.textMain,
              ),
              child: const Text('在浏览器打开'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showShareDialog() async {
    final String shareUrl = widget.shareUrl.trim();
    final String link = shareUrl.isNotEmpty
        ? shareUrl
        : (_currentUrl.trim().isNotEmpty ? _currentUrl : widget.url);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '分享链接',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          content: SelectableText(
            link,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('链接已复制，正在打开系统分享...')),
                );
                await _shareLink(link);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.duckYellow,
                foregroundColor: AppTokens.textMain,
              ),
              child: const Text('复制并转发'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareLink(String link) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: link, subject: widget.title),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未能打开系统分享，请稍后重试。')),
      );
    }
  }

  Future<void> _openInBrowser(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
