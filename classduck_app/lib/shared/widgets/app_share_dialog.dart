import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/survey_links.dart';
import '../theme/app_tokens.dart';

class AppShareDialog {
  AppShareDialog._();

  static const String _guideText = '邀请同学一起用上课鸭管理课表和待办，学习安排更省心。';

  static String get _shareMessage => '$_guideText\n${SurveyLinks.projectShareUrl}';

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '分享上课鸭',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                _guideText,
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black),
              ),
              const SizedBox(height: AppTokens.space12),
              SelectableText(
                SurveyLinks.projectShareUrl,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _copyLink(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('复制链接'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _copyAndShare(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.duckYellow,
                foregroundColor: Colors.white,
              ),
              child: const Text('复制并分享'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _copyLink(BuildContext context) async {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(const ClipboardData(text: SurveyLinks.projectShareUrl));
    messenger?.showSnackBar(const SnackBar(content: Text('链接已复制')));
  }

  static Future<void> _copyAndShare(BuildContext context) async {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    await Clipboard.setData(const ClipboardData(text: SurveyLinks.projectShareUrl));
    messenger?.showSnackBar(const SnackBar(content: Text('链接已复制，正在打开系统分享...')));

    try {
      await SharePlus.instance.share(
        ShareParams(text: _shareMessage, subject: '上课鸭'),
      );
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('未能打开系统分享，请稍后重试。')),
      );
    }
  }
}
