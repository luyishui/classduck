import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/appearance_state.dart';
import '../../../shared/theme/app_tokens.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppearanceState>(
      valueListenable: AppearanceStore.state,
      builder:
          (BuildContext context, AppearanceState appearance, Widget? child) {
            return Scaffold(
              backgroundColor: AppTokens.pageBackground,
              appBar: AppBar(
                backgroundColor: AppTokens.pageBackground,
                surfaceTintColor: Colors.transparent,
                centerTitle: true,
                title: const Text(
                  '外观与主题',
                  style: TextStyle(
                    color: AppTokens.textMain,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                children: <Widget>[
                  const Text(
                    '背景图片',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          appearance.backgroundBytes == null
                              ? '当前未设置背景图片'
                              : '当前图片：${appearance.backgroundName ?? '未命名'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTokens.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('上传背景图片'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _uploadBackgroundImage,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            '清除背景图片',
                            style: TextStyle(color: Color(0xFFE06565)),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFE06565),
                          ),
                          onTap: _clearBackgroundImage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Future<void> _uploadBackgroundImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted || file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      AppearanceStore.setBackground(bytes: bytes, name: file.name);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('背景图片已选择，课程表背景接入将在后续任务完成。')));
  }

  void _clearBackgroundImage() {
    setState(() {
      AppearanceStore.clearBackground();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('背景图片已清除。')));
  }
}
