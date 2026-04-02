import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_motion.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/duck_pressable.dart';
import '../../schedule/data/schedule_repository.dart';
import '../application/import_engine.dart';
import 'import_execution_page.dart';

// ──────────────────────────────────────────────────────────
// 豆包 AI 课表识别提示词（复制给豆包的完整 prompt）
// ──────────────────────────────────────────────────────────
const String kDoubaoImportPrompt = '''请识别课表截图中的所有课程，按以下 JSON 格式输出。

每门课一个 JSON 对象，字段如下：
- "n": 课程全名（字符串，与图片完全一致）
- "d": 星期几（数字：1=周一,2=周二,3=周三,4=周四,5=周五,6=周六,7=周日）
- "s": 开始小节（数字，从1开始）
- "e": 结束小节（数字，必须 >= s）
- "w": 上课周次（字符串，如 "1-16" 或 "1,3,5-8"）
- "l": 上课地点（字符串，没有则填 null）
- "t": 教师姓名（字符串，没有则填 null）

大节 -> 小节映射（1大节 = 2小节）：
第1大节 -> s=1,e=2
第2大节 -> s=3,e=4
第3大节 -> s=5,e=6
第4大节 -> s=7,e=8
第5大节 -> s=9,e=10

如果行标是"1-2节""3-4节"，同上对应。
如果是每行 1 小节，则直接用行号。

周次规则：
去掉"周"字，连续写"1-16"，不连续写"1,3,5"，混合写"1-8,10,12"。
单周展开为奇数，双周展开为偶数。
w 中范围前面的数必须 <= 后面的数。

重要规则：
- 一个格子内有多门课（不同周次）必须分别输出
- 没有明确星期和节次的课程不要输出
- 课程名中的括号、数字、英文必须完整保留
- d 只能是 1-7 的数字，s 和 e 只能是 >= 1 的数字

输出示例：
[
  {"n":"高等数学","d":1,"s":1,"e":2,"w":"1-16","l":"A101","t":"张三"},
  {"n":"大学英语(4)","d":3,"s":3,"e":4,"w":"1-8","l":"B202","t":"李四"},
  {"n":"实验课","d":5,"s":5,"e":8,"w":"1-16","l":"C301","t":null}
]

请直接输出 JSON 数组：''';

// ──────────────────────────────────────────────────────────
// DoubaoImportPage — 3 步 PageView 向导式导入
//
// 【整体架构】
// 使用 PageView 实现左右滑动的三步导入流程：
//   Step 1 截图准备 → Step 2 AI 识别 → Step 3 粘贴导入
// 顶部分段进度条实时指示当前步骤，底部按钮可前进/后退。
// 从豆包 App 切回时自动检测剪贴板是否包含 JSON 数据。
// 导入成功后弹出课表命名对话框，用户可自定义课表名称。
// ──────────────────────────────────────────────────────────
class DoubaoImportPage extends StatefulWidget {
  const DoubaoImportPage({
    super.key,
    this.sourceLabel,
  });

  /// 从教务页跳转过来时，带上来源标签（如学校名称）。
  final String? sourceLabel;

  @override
  State<DoubaoImportPage> createState() => _DoubaoImportPageState();
}

class _DoubaoImportPageState extends State<DoubaoImportPage>
    with WidgetsBindingObserver {
  // ── 核心依赖 ──
  final ImportEngine _importEngine = ImportEngine();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();

  // ── PageView 控制 ──
  late final PageController _pageController;
  int _currentStep = 0;
  static const int _totalSteps = 3;

  // ── Step 3 表单 ──
  final TextEditingController _resultController = TextEditingController();
  bool _importing = false;
  bool _clipboardChecked = false;

  // ── 3 步标题 ──
  static const List<String> _stepTitles = <String>[
    '准备课表截图',
    'AI 识别课表',
    '粘贴并导入',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────
  // 当用户从豆包切回 App 时，自动检测剪贴板中是否有 JSON
  // 原理：WidgetsBindingObserver 监听 AppLifecycleState.resumed，
  // 如果当前在 Step 3 且尚未检测，则读取剪贴板并判断是否为 JSON 数组。
  // ────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentStep == 2) {
      _autoDetectClipboard();
    }
  }

  Future<void> _autoDetectClipboard() async {
    if (_clipboardChecked || _importing) return;
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;

    // 简单判断是否包含 JSON 数组特征
    final bool looksLikeJson =
        (text.startsWith('[') && text.endsWith(']')) ||
        (text.contains('"n"') && text.contains('"d"'));

    if (looksLikeJson && mounted && _resultController.text.trim().isEmpty) {
      setState(() {
        _resultController.text = text;
        _resultController.selection =
            TextSelection.collapsed(offset: text.length);
        _clipboardChecked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已从剪贴板自动识别到课程数据'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF4A9960),
        ),
      );
    }
  }

  // ── 页面切换 ──
  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    _pageController.animateToPage(
      step,
      duration: AppMotion.regular,
      curve: AppMotion.standard,
    );
    setState(() => _currentStep = step);
  }

  // ────────────────────────────────────────────
  // Step 2: 复制提示词并跳转豆包
  // 先将 kDoubaoImportPrompt 写入系统剪贴板，
  // 然后通过 url_launcher 打开豆包 Web 页面。
  // 跳转后自动滑到 Step 3 等待粘贴。
  // ────────────────────────────────────────────
  Future<void> _copyAndOpenDoubao() async {
    await Clipboard.setData(const ClipboardData(text: kDoubaoImportPrompt));
    if (!mounted) return;

    final Uri uri = Uri.parse('https://www.doubao.com/chat/');
    final bool launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;
    if (launched) {
      setState(() => _clipboardChecked = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('提示词已复制，把截图和提示词一起发给豆包吧'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _goToStep(2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('无法打开豆包，请手动打开后粘贴提示词'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Step 3: 手动粘贴 ──
  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('剪贴板里没有可用文本'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() {
      _resultController.text = text;
      _resultController.selection =
          TextSelection.collapsed(offset: text.length);
    });
  }

  // ────────────────────────────────────────────
  // Step 3: 执行导入
  // 1. 校验输入是否为空
  // 2. 检查是否存在课表 → 若有则弹出冲突决策对话框
  // 3. 调用 ImportEngine.importFromDoubaoText() 解析+入库
  // 4. 成功后弹出命名对话框让用户给课表起名
  // 5. 用 renameCourseTable 更新名称后返回课程表页面
  // ────────────────────────────────────────────
  Future<void> _runImport() async {
    final String content = _resultController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先粘贴豆包返回的课程数据'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _importing = true);

    // 冲突检测
    ImportConflictMode mode = ImportConflictMode.createNew;
    final int tableCount =
        (await _scheduleRepository.getCourseTables()).length;
    if (tableCount > 0 && mounted) {
      final ImportConflictMode? selected =
          await showDialog<ImportConflictMode>(
        context: context,
        builder: (BuildContext ctx) => const ImportConflictDialog(),
      );
      if (selected == null) {
        setState(() => _importing = false);
        return;
      }
      mode = selected;
    }

    try {
      final ImportExecutionResult result =
          await _importEngine.importFromDoubaoText(
        content,
        tableName: '豆包导入课表',
        mode: mode,
      );
      if (!mounted) return;

      // 导入成功 → 弹出命名对话框
      final String? customName =
          await _showNamingDialog(result.importedCount);
      if (customName != null && customName.trim().isNotEmpty) {
        await _scheduleRepository.renameCourseTable(
          tableId: result.courseTableId,
          newName: customName.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导入失败：$error'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFFD14545),
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ────────────────────────────────────────────
  // 导入成功命名对话框
  // 显示成功图标 + 课程数 + 课表名称输入框 + 完成按钮。
  // 用户填写名称后点击完成，返回名称字符串。
  // ────────────────────────────────────────────
  Future<String?> _showNamingDialog(int count) async {
    final TextEditingController nameCtrl =
        TextEditingController(text: '我的课表');
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: Column(
            children: <Widget>[
              // 成功图标
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F9ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF4A9960), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                '导入成功！共 $count 门课程',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.textMain,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '给课表起个名字',
              hintStyle: const TextStyle(color: AppTokens.textMuted),
              filled: true,
              fillColor: const Color(0xFFF7F5F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(nameCtrl.text),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.duckYellow,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('完成',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────
  // UI 构建
  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (int index) {
                  setState(() => _currentStep = index);
                  if (index == 2) _autoDetectClipboard();
                },
                children: <Widget>[
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── 顶栏：返回 + 步骤标题 + 步骤编号 ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (_currentStep > 0) {
                _goToStep(_currentStep - 1);
              } else {
                Navigator.of(context).maybePop();
              }
            },
            color: AppTokens.textMain,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  _stepTitles[_currentStep],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_currentStep + 1} / $_totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── 分段进度条：3 段，已完成的段为黄色，未完成为灰色 ──
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Row(
        children: List<Widget>.generate(_totalSteps, (int i) {
          final bool active = i <= _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: AppMotion.regular,
              curve: AppMotion.standard,
              height: 4,
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
              decoration: BoxDecoration(
                color: active
                    ? AppTokens.duckYellow
                    : const Color(0xFFE8E4DF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Step 1: 准备截图
  // 展示一个居中的大图标 + 文字说明，引导用户先准备好课表截图。
  // 如果从教务页跳转过来，额外显示来源标签提示。
  // 底部有一条小 tip 提示截图要包含完整信息。
  // ────────────────────────────────────────────
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: <Widget>[
          const Spacer(flex: 1),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppTokens.duckYellowSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.screenshot_monitor_rounded,
                size: 48, color: Color(0xFFD4A017)),
          ),
          const SizedBox(height: 28),
          const Text(
            '先截取你的课表',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTokens.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '打开教务系统或课表App\n截取完整的课程表截图',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTokens.textMain.withValues(alpha: 0.6),
            ),
          ),
          if (widget.sourceLabel != null &&
              widget.sourceLabel!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4CC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFB98500)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '来自 ${widget.sourceLabel} 的导入流程',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB98500),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(flex: 1),
          _buildTipCard(
            icon: Icons.lightbulb_outline_rounded,
            text: '确保截图包含完整的星期、节次和课程名称',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // Step 2: AI 识别
  // 居中大图标 + 说明文字 + 核心操作按钮（复制提示词并跳转豆包）。
  // 底部有三步小提示条，让用户清楚知道在豆包里要做什么。
  // ────────────────────────────────────────────
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: <Widget>[
          const Spacer(flex: 1),
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFFFF4CC), Color(0xFFFFE88A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 48, color: Color(0xFFD4A017)),
          ),
          const SizedBox(height: 28),
          const Text(
            '让豆包识别课表',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTokens.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击下方按钮，自动复制提示词\n跳转到豆包后，发送截图即可',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTokens.textMain.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          // 核心操作按钮
          DuckPressable(
            onTap: _copyAndOpenDoubao,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFFFC93C), Color(0xFFFFB800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x30D4A017),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.content_copy_rounded,
                      size: 20, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    '复制提示词并跳转豆包',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 1),
          _buildMiniSteps(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Step 2 底部的三步小提示条：复制提示词 → 发送截图 → 复制结果
  Widget _buildMiniSteps() {
    const List<String> tips = <String>[
      '复制提示词',
      '发截图给豆包',
      '复制结果',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EDE8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(tips.length, (int i) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTokens.duckYellowSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB98500),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                tips[i],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTokens.textMuted,
                ),
              ),
              if (i < tips.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppTokens.textMuted),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ────────────────────────────────────────────
  // Step 3: 粘贴并导入
  // 顶部标题说明 + 大文本输入框（带粘贴/清空操作栏）
  // + 补充说明卡片（导入后还需要做的事）。
  // 支持从剪贴板自动检测和手动粘贴两种方式。
  // ────────────────────────────────────────────
  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: <Widget>[
        const Text(
          '粘贴豆包的识别结果',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTokens.textMain,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '从豆包复制 JSON 结果后粘贴到下方',
          style: TextStyle(
            fontSize: 14,
            color: AppTokens.textMain.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 20),
        // 粘贴输入区
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0EDE8)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _resultController,
                minLines: 10,
                maxLines: 16,
                decoration: InputDecoration(
                  hintText:
                      '支持纯 JSON 或带代码块的结果\n\n[\n  {"n":"高等数学","d":1,...},\n  ...\n]',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppTokens.textMuted.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTokens.textMain,
                  fontFamily: 'monospace',
                ),
              ),
              // 粘贴/清空操作栏
              Container(
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: Color(0xFFF0EDE8))),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton.icon(
                        onPressed:
                            _importing ? null : _pasteFromClipboard,
                        icon: const Icon(
                            Icons.content_paste_go_rounded,
                            size: 18),
                        label: const Text('从剪贴板粘贴'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB98500),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 20,
                        color: const Color(0xFFF0EDE8)),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _importing
                            ? null
                            : () => _resultController.clear(),
                        icon:
                            const Icon(Icons.clear_rounded, size: 18),
                        label: const Text('清空'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTokens.textMuted,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 补充说明
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF4E4B8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFB98500)),
                  SizedBox(width: 6),
                  Text(
                    '导入后你可能还需要',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB98500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildHintItem('在课表侧边栏确认每日课程节数'),
              _buildHintItem('调整学期周数'),
              _buildHintItem('配置每节课的具体时间'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHintItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFD4A017),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // 底部导航栏
  // Step 0: 只有"下一步"
  // Step 1-2: "上一步" + "下一步"/"确认导入"
  // 导入中时按钮显示 loading 状态且不可点击。
  // ────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0EDE8))),
      ),
      child: Row(
        children: <Widget>[
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goToStep(_currentStep - 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.textMain,
                  side: const BorderSide(color: Color(0xFFE0DCD6)),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('上一步',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: _currentStep < _totalSteps - 1
                ? FilledButton(
                    onPressed: () => _goToStep(_currentStep + 1),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.duckYellow,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('下一步',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  )
                : FilledButton.icon(
                    onPressed: _importing ? null : _runImport,
                    icon: _importing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.playlist_add_check_rounded),
                    label: Text(
                      _importing ? '导入中...' : '确认导入',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.duckYellow,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 通用提示卡片组件 ──
  Widget _buildTipCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EDE8)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFFD4A017)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTokens.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
