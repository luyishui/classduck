import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_tokens.dart';

class LegalDocumentsPage extends StatefulWidget {
  const LegalDocumentsPage({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  State<LegalDocumentsPage> createState() => _LegalDocumentsPageState();
}

class _LegalDocumentsPageState extends State<LegalDocumentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 1),
  );

  late final Future<String> _serviceAgreementFuture =
      rootBundle.loadString('docs/legal/service-agreement-draft.md');
  late final Future<String> _privacyPolicyFuture =
      rootBundle.loadString('docs/legal/privacy-policy-draft.md');

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTokens.pageBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          '服务协议与隐私政策',
          style: TextStyle(
            color: AppTokens.textMain,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTokens.textMain,
          unselectedLabelColor: AppTokens.textMuted,
          indicatorColor: AppTokens.duckYellow,
          tabs: const <Tab>[
            Tab(text: '服务协议'),
            Tab(text: '隐私政策'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _LegalMarkdownView(markdownFuture: _serviceAgreementFuture),
          _LegalMarkdownView(markdownFuture: _privacyPolicyFuture),
        ],
      ),
    );
  }
}

class _LegalMarkdownView extends StatelessWidget {
  const _LegalMarkdownView({required this.markdownFuture});

  final Future<String> markdownFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: markdownFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '法律文档加载失败，请稍后重试。',
                style: TextStyle(
                  color: AppTokens.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SelectableText(
              _plainText(snapshot.data!),
              style: const TextStyle(
                color: AppTokens.textMain,
                fontSize: 14,
                height: 1.65,
              ),
            ),
          ),
        );
      },
    );
  }

  String _plainText(String markdown) {
    final String cleaned = markdown
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ')
        .replaceAll('**', '')
        .replaceAll('`', '');

    final List<String> lines = cleaned.split('\n');
    final List<String> formatted = <String>[];
    bool pendingBlankLine = false;

    for (final String rawLine in lines) {
      final String line = rawLine.trim();
      if (line.isEmpty) {
        pendingBlankLine = true;
        continue;
      }

      final bool isChapterTitle = RegExp(r'^[一二三四五六七八九十]+、').hasMatch(line);
      if (isChapterTitle) {
        if (formatted.isNotEmpty && formatted.last.isNotEmpty) {
          formatted.add('');
        }
        formatted.add(line);
        formatted.add('');
        pendingBlankLine = false;
        continue;
      }

      if (pendingBlankLine && formatted.isNotEmpty && formatted.last.isNotEmpty) {
        formatted.add('');
      }
      formatted.add(line);
      pendingBlankLine = false;
    }

    return formatted.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
