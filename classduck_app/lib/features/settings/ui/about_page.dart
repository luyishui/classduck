import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/duck_modal.dart';
import '../data/release_repository.dart';
import 'legal_documents_page.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const String _currentVersion = 'v1.0.0';
  final ReleaseRepository _releaseRepository = ReleaseRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppTokens.pageBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          color: AppTokens.textMain,
          iconSize: 28,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '关于上课鸭',
          style: TextStyle(
            color: AppTokens.textMain,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 26),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1A2E2011),
                    blurRadius: 40,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  _AboutActionRow(
                    icon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppTokens.textMuted,
                    ),
                    label: '联系邮箱',
                    trailing: SizedBox(
                      height: 32,
                      child: FilledButton(
                        onPressed: _copyContactEmail,
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppTokens.duckYellow,
                          foregroundColor: AppTokens.textMain,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('复制'),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0ECE4)),
                  _AboutActionRow(
                    icon: const Icon(
                      Icons.description_outlined,
                      color: AppTokens.textMuted,
                    ),
                    label: '服务协议',
                    onTap: _openServiceAgreement,
                  ),
                  const Divider(height: 1, color: Color(0xFFF0ECE4)),
                  _AboutActionRow(
                    icon: const Icon(
                      Icons.article_outlined,
                      color: AppTokens.textMuted,
                    ),
                    label: '隐私政策',
                    onTap: _openPrivacyPolicy,
                  ),
                  const Divider(height: 1, color: Color(0xFFF0ECE4)),
                  _AboutActionRow(
                    icon: const Icon(
                      Icons.system_update_alt_rounded,
                      color: AppTokens.textMuted,
                    ),
                    label: '版本更新',
                    value: _currentVersion,
                    onTap: _checkUpdate,
                  ),
                ],
              ),
            ),
            const Spacer(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _copyContactEmail() async {
    await Clipboard.setData(const ClipboardData(text: 'classduck@163.com'));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('联系邮箱已复制')),
    );
  }

  void _openServiceAgreement() {
    _openLegalDocuments(initialTab: 0);
  }

  void _openPrivacyPolicy() {
    _openLegalDocuments(initialTab: 1);
  }

  void _openLegalDocuments({required int initialTab}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            LegalDocumentsPage(initialTab: initialTab),
      ),
    );
  }

  Future<void> _checkUpdate() async {
    final _VersionCheckResult result = await _loadVersionCheckResult();

    if (!mounted) {
      return;
    }

    if (result.hasNewVersion) {
      await _showFoundNewVersionModal(result);
      return;
    }

    await _showLatestModal();
  }

  Future<_VersionCheckResult> _loadVersionCheckResult() async {
    try {
      // 前后端分离：版本信息由后端 release 服务给出，前端只负责展示与交互。
      final ReleaseCheckResult result = await _releaseRepository.checkRelease(
        currentVersion: _currentVersion.replaceFirst('v', ''),
        platform: 'android',
      );
      return _VersionCheckResult(
        currentVersion: result.currentVersion,
        latestVersion: result.latestVersion,
        releaseNotes: result.releaseNotes,
        updateUrl: result.updateUrl,
      );
    } catch (_) {
      // 兜底：后端不可用时继续保留本地默认值，保证更新弹窗链路可用。
      return const _VersionCheckResult(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        releaseNotes:
            '1. 新增：课程提醒可自定义提前时间\n2. 优化：导入课表稳定性与速度\n3. 修复：部分机型弹窗错位问题\n4. 细节：多处文案与交互动效调整',
        updateUrl: 'https://example.com/classduck/android',
      );
    }
  }

  Future<void> _showLatestModal() {
    return DuckModal.show<void>(
      context: context,
      barrierColor: const Color(0x66000000),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 336,
          height: 196,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            color: AppTokens.pageBackground,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: <Widget>[
              const Text(
                '检查更新',
                style: TextStyle(
                  color: AppTokens.textMain,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎉 当前已是最新版本 v1.0.0 🎊',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8F8A84),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 288,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppTokens.duckYellow,
                    foregroundColor: AppTokens.textMain,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('我知道了'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFoundNewVersionModal(_VersionCheckResult result) {
    return DuckModal.show<void>(
      context: context,
      barrierColor: const Color(0x66000000),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 336,
          height: 268,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
          decoration: BoxDecoration(
            color: AppTokens.pageBackground,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '发现新版本',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTokens.textMain,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'v${result.latestVersion} 可用，是否立即更新？',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8F8A84),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 74,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    result.releaseNotes,
                    style: const TextStyle(
                      color: Color(0xFF7D7770),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                    width: 136,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFF2EFE8),
                        foregroundColor: AppTokens.textMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('暂不更新'),
                    ),
                  ),
                  SizedBox(
                    width: 136,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('正在跳转到更新页面：${result.updateUrl}')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppTokens.duckYellow,
                        foregroundColor: AppTokens.textMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('立即更新'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionCheckResult {
  const _VersionCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.updateUrl,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String updateUrl;

  bool get hasNewVersion => currentVersion != latestVersion;
}

class _AboutActionRow extends StatelessWidget {
  const _AboutActionRow({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              SizedBox(width: 22, child: Center(child: icon)),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: AppTokens.textMain,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    value!,
                    style: const TextStyle(
                      color: AppTokens.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFAEA79E),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
