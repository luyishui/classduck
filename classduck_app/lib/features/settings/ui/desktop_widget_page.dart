import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

/// 桌面小组件预览与指引页面
class DesktopWidgetPage extends StatefulWidget {
  const DesktopWidgetPage({super.key});

  @override
  State<DesktopWidgetPage> createState() => _DesktopWidgetPageState();
}

class _DesktopWidgetPageState extends State<DesktopWidgetPage> {
  int _selectedSpec = 0; // 0: 2x2, 1: 4x2, 2: 4x4

  final List<String> _specDescriptions = [
    '2×2 紧凑单日卡片 · 响应式智能充实，紧凑精致无缝隙',
    '4×2 双栏日程流 · 紧凑聚焦双课，清晰呈现今日作息',
    '4×4 多日时段网格 · 5~7 天网格总览，早中晚作息一览无余',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      appBar: AppBar(
        title: const Text(
          '桌面小组件',
          style: TextStyle(
            color: Color(0xFF40352A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF40352A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 规格选择器
            _buildSegmentedControl(),
            const SizedBox(height: 18),

            // 桌面壁纸衬托舞台
            _buildStage(),
            const SizedBox(height: 14),

            // 规格文字描述
            Text(
              _specDescriptions[_selectedSpec],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFA3978A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // 添加按钮
            _buildAddButton(),
            const SizedBox(height: 22),

            // 使用指引卡片（无 emoji，素雅纯粹）
            _buildGuideCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 规格三段式选择器
  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAE0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildSegmentItem(0, '小尺寸 (2×2)', '聚焦单日'),
          _buildSegmentItem(1, '中尺寸 (4×2)', '日程流'),
          _buildSegmentItem(2, '大尺寸 (4×4)', '多日网格'),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(int index, String title, String subtitle) {
    final isSelected = _selectedSpec == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSpec = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2E2011).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF40352A) : const Color(0xFFA3978A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFFD19B00) : const Color(0xFFA3978A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 手机壁纸舞台
  Widget _buildStage() {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [Color(0xFF34482E), Color(0xFF1A2617)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildCurrentWidget(),
      ),
    );
  }

  Widget _buildCurrentWidget() {
    switch (_selectedSpec) {
      case 0:
        return _buildSmallWidget();
      case 1:
        return _buildMediumWidget();
      case 2:
      default:
        return _buildLargeWidget();
    }
  }

  /// 1. 小尺寸 (2×2) 单日聚焦卡片：响应式紧凑双课充实流，品牌金黄斜杠
  Widget _buildSmallWidget() {
    return Container(
      key: const ValueKey('small_2x2'),
      width: 164,
      height: 164,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部日期与课数（黄色斜杠）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F1A14),
                    letterSpacing: -1,
                    height: 1,
                  ),
                  children: [
                    TextSpan(text: '9'),
                    TextSpan(
                      text: '/',
                      style: TextStyle(
                        color: Color(0xFFFFC93C), // 上课鸭品牌金黄色斜杠
                        fontSize: 24,
                      ),
                    ),
                    TextSpan(text: '7'),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '周一',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1A14),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '今日 2 节',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8C7E72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 双课充实日程流
          Expanded(
            child: Column(
              children: [
                // 1. 进行中课程
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFF1B8), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE86B79),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '技术创新管理',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1F1A14),
                                        height: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC93C),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '进行中',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF40352A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '10:10-12:00 · 教2楼',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF8C7E72),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // 2. 后续课程
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4A88D2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '创新创业与战略',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F1A14),
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                '16:40-18:15 · 理科楼',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF8C7E72),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. 中尺寸 (4×2) 双栏日程流卡片：品牌金黄斜杠，居中平衡，虚线分割，双课流
  Widget _buildMediumWidget() {
    return Container(
      key: const ValueKey('medium_4x2'),
      width: 334,
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左栏看板：垂直居中聚合，绝不下沉
          SizedBox(
            width: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F1A14),
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                    children: [
                      TextSpan(text: '9'),
                      TextSpan(
                        text: '/',
                        style: TextStyle(
                          color: Color(0xFFFFC93C), // 上课鸭品牌金黄色斜杠
                          fontSize: 24,
                        ),
                      ),
                      TextSpan(text: '7'),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '周一',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1A14),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '第 3 周',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA37900),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '今日 2 节课',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8C7E72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // 虚线分割
          const _DashedDivider(
            color: Color(0xFFE6DEC8),
            dashHeight: 3.0,
            dashGap: 2.5,
            strokeWidth: 1.2,
          ),
          const SizedBox(width: 14),

          // 右栏：今日日程流（双课紧凑排布）
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 进行中课程
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFF1B8), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE86B79),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    '技术创新管理',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1F1A14),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC93C),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '进行中',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF40352A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '10:10 - 12:00 · 教2楼-西207',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8C7E72),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 2. 后续课程
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A88D2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '创新创业与战略学术',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F1A14),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              '16:40 - 18:15 · 理科楼 A302',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8C7E72),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  /// 3. 大尺寸 (4×4) 无界流动多日网格：严格五等分绝对等宽，课程名称与图片完全一致
  Widget _buildLargeWidget() {
    return Container(
      key: const ValueKey('large_4x4'),
      width: 334,
      height: 258,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 表头：5 列严格绝对等宽
          Row(
            children: [
              _buildLargeColHeader('教师节', '10', false),
              _buildLargeColHeader('周五', '11', true), // 今日高亮
              _buildLargeColHeader('周六', '12', false),
              _buildLargeColHeader('周日', '13', false),
              _buildLargeColHeader('周一', '14', false),
            ],
          ),
          const SizedBox(height: 10),

          // 主体：开放式通透网格，每一列均分等宽（Expanded），右侧细边框，最后一列无边框
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLargeDayColumn([
                  _buildMiniCard('技术创新管理', '10:10', const Color(0xFFFFFDF4), const Color(0xFFE86B79), borderColor: const Color(0xFFFFF1B8)),
                  _buildMiniCard('创新创业与战略', '16:40', const Color(0xFFFAF7F2), const Color(0xFF4A88D2)),
                ], hasRightBorder: true),
                _buildLargeDayColumn([
                  _buildMiniCard('高等数学', '09:00', const Color(0xFFFFF0F3), const Color(0xFFE86B79)),
                  _buildMiniCard('大学物理实验', '10:10', const Color(0xFFFFF0F3), const Color(0xFFE86B79)),
                ], hasRightBorder: true),
                _buildLargeDayColumn([], hasRightBorder: true), // 周六：纯净留白
                _buildLargeDayColumn([], hasRightBorder: true), // 周日：纯净留白
                _buildLargeDayColumn([
                  _buildMiniCard('技术创新管理', '10:10', const Color(0xFFFFFDF4), const Color(0xFFE86B79), borderColor: const Color(0xFFFFF1B8)),
                ], hasRightBorder: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeColHeader(String weekday, String day, bool isToday) {
    return Expanded(
      child: Column(
        children: [
          Text(
            weekday,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? const Color(0xFF1F1A14) : const Color(0xFF8C7E72),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFFFC93C) : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w800,
                color: const Color(0xFF1F1A14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeDayColumn(List<Widget> cards, {bool hasRightBorder = true}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          border: hasRightBorder
              ? const Border(
                  right: BorderSide(color: Color(0xFFF0ECE4), width: 1),
                )
              : null,
        ),
        padding: EdgeInsets.only(right: hasRightBorder ? 3 : 0),
        child: Column(
          children: [
            for (final card in cards) ...[
              card,
              const SizedBox(height: 8),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCard(
    String title,
    String time,
    Color bgColor,
    Color dotColor, {
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4.5,
                height: 4.5,
                margin: const EdgeInsets.only(top: 3.5, right: 3),
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1A14),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 7.5),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF8C7E72),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 通过系统「添加到主屏幕」确认框，把当前选中的规格钉选到桌面。
  /// 定制桌面不支持钉选（或 Android 8 以下）时，回退为手动添加指引。
  Future<void> _addCurrentWidgetToHomeScreen() async {
    const List<String> receiverClassNames = <String>[
      'io.github.luyishui.classduck.widget.ClassDuckSmallWidgetReceiver',
      'io.github.luyishui.classduck.widget.ClassDuckMediumWidgetReceiver',
      'io.github.luyishui.classduck.widget.ClassDuckLargeWidgetReceiver',
    ];
    final String qualifiedName = receiverClassNames[_selectedSpec];
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    Future<void> showManualGuideTip() async {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('长按手机桌面空白处，选择【上课鸭】即可添加！'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (kIsWeb || !Platform.isAndroid) {
      await showManualGuideTip();
      return;
    }
    try {
      final bool? supported = await HomeWidget.isRequestPinWidgetSupported();
      if (supported != true) {
        await showManualGuideTip();
        return;
      }
      await HomeWidget.requestPinWidget(qualifiedAndroidName: qualifiedName);
    } catch (_) {
      await showManualGuideTip();
    }
  }

  /// 添加按钮
  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: _addCurrentWidgetToHomeScreen,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC93C),
        foregroundColor: const Color(0xFF40352A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        shadowColor: const Color(0xFFFFC93C).withValues(alpha: 0.35),
      ),
      child: const Text(
        '＋ 添加当前小组件到桌面',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  /// 使用指引卡片（无 emoji，素雅纯粹）
  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E2011).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '添加小组件指引',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF40352A),
            ),
          ),
          const SizedBox(height: 14),
          _buildGuideStep('1', '返回手机桌面，长按桌面空白区域'),
          _buildGuideStep('2', '在弹出菜单中点击【小组件】或【微件】'),
          _buildGuideStep('3', '在列表中找到【上课鸭】，挑选您喜欢的尺寸'),
          _buildGuideStep('4', '按住并拖拽到桌面合适位置，松手即可完成！', isLast: true),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '提示：小组件已为您精心优化核心日程排布，点击小组件任意区域即可秒级直达应用查看完整课表。',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF8C7E72),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String num, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2, right: 10),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF4CC),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD19B00),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF40352A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 优雅的纵向虚线小组件
class _DashedDivider extends StatelessWidget {
  const _DashedDivider({
    this.color = const Color(0xFFE6DEC8),
    this.dashHeight = 3.0,
    this.dashGap = 2.5,
    this.strokeWidth = 1.2,
  });

  final Color color;
  final double dashHeight;
  final double dashGap;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 120.0;
        final count = (totalHeight / (dashHeight + dashGap)).floor();
        return SizedBox(
          width: strokeWidth,
          height: totalHeight,
          child: Column(
            verticalDirection: VerticalDirection.down,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (_) {
              return SizedBox(
                width: strokeWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
