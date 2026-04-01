import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../schedule/data/schedule_repository.dart';
import '../application/import_engine.dart';
import 'import_execution_page.dart';

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

如果行标是“1-2节”“3-4节”，同上对应。
如果是每行 1 小节，则直接用行号。

周次规则：
去掉“周”字，连续写“1-16”，不连续写“1,3,5”，混合写“1-8,10,12”。
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

class DoubaoImportPage extends StatefulWidget {
  const DoubaoImportPage({
    super.key,
    this.initialTableName = '豆包导入课表',
    this.sourceLabel,
    this.autoCopyPrompt = false,
  });

  final String initialTableName;
  final String? sourceLabel;
  final bool autoCopyPrompt;

  @override
  State<DoubaoImportPage> createState() => _DoubaoImportPageState();
}

class _DoubaoImportPageState extends State<DoubaoImportPage> {
  final ImportEngine _importEngine = ImportEngine();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();

  late final TextEditingController _tableNameController;
  final TextEditingController _resultController = TextEditingController();

  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _tableNameController = TextEditingController(text: widget.initialTableName);

    if (widget.autoCopyPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _copyPrompt(showMessage: true);
      });
    }
  }

  @override
  void dispose() {
    _tableNameController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('大学课程导入'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: <Widget>[
          if (widget.sourceLabel != null &&
              widget.sourceLabel!.trim().isNotEmpty) ...<Widget>[
            _HeroCard(sourceLabel: widget.sourceLabel!.trim()),
            const SizedBox(height: 10),
          ],
          _InfoCard(
            title: '快速操作',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const <Widget>[
                _StepLine(index: 1, text: '在添加按钮中选择“大学课程导入”。'),
                _StepLine(index: 2, text: '点击下方按钮，复制提示词并跳转豆包。'),
                _StepLine(index: 3, text: '把课表截图和提示词一起发送给豆包。'),
                _StepLine(index: 4, text: '复制结果，回到这里粘贴并导入。'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _importing ? null : _startDoubaoFlow,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('一键复制提示词并跳转豆包'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.duckYellow,
              foregroundColor: AppTokens.textMain,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            title: '提示词',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF4E4B8)),
                  ),
                  child: SelectableText(
                    kDoubaoImportPrompt,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: AppTokens.textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            title: '导入设置',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _tableNameController,
                  decoration: const InputDecoration(
                    labelText: '课表名称',
                    hintText: '例如：2025-2026 学年第一学期',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _resultController,
                  minLines: 8,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    labelText: '粘贴豆包结果',
                    hintText: '支持纯 JSON，也支持带代码块的 JSON 结果。',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _importing ? null : _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_go_rounded),
                  label: const Text('从剪贴板粘贴'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            title: '补充说明',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                _HintLine(text: '课程节数需要你在课表侧边栏里额外确认，例如 14 节。'),
                _HintLine(text: '学期周数需要你自己调整，例如 25 周。'),
                _HintLine(text: '课表时间也需要你后续配置；如果时长不一，可关闭统一时长后逐节编辑。'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _importing ? null : () => _runImport(),
            icon: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check_rounded),
            label: Text(_importing ? '正在导入...' : '粘贴结果并导入'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.duckYellow,
              foregroundColor: AppTokens.textMain,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDoubaoFlow() async {
    await _copyPrompt(showMessage: false);
    await _openDoubao();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('提示词已复制，现在把截图和提示词一起发给豆包。')));
  }

  Future<void> _copyPrompt({required bool showMessage}) async {
    await Clipboard.setData(const ClipboardData(text: kDoubaoImportPrompt));
    if (!mounted || !showMessage) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('提示词已复制。')));
  }

  Future<void> _openDoubao() async {
    final Uri uri = Uri.parse('https://www.doubao.com/chat/');
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('无法打开豆包，请手动打开。')));
    }
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('剪贴板里没有可用文本。')));
      return;
    }

    setState(() {
      _resultController.text = text;
      _resultController.selection = TextSelection.collapsed(
        offset: _resultController.text.length,
      );
    });
  }

  Future<void> _runImport({bool loadClipboardFirst = false}) async {
    String content = _resultController.text.trim();
    if (loadClipboardFirst) {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) {
        return;
      }
      final String clipboardText = data?.text?.trim() ?? '';
      if (clipboardText.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('剪贴板里没有可导入内容。')));
        return;
      }
      content = clipboardText;
      _resultController.text = clipboardText;
      _resultController.selection = TextSelection.collapsed(
        offset: _resultController.text.length,
      );
    }

    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先粘贴豆包返回结果。')));
      return;
    }

    setState(() {
      _importing = true;
    });

    ImportConflictMode mode = ImportConflictMode.createNew;
    final int tableCount = (await _scheduleRepository.getCourseTables()).length;
    if (tableCount > 0) {
      if (!mounted) {
        setState(() {
          _importing = false;
        });
        return;
      }
      final ImportConflictMode? selected = await showDialog<ImportConflictMode>(
        context: context,
        builder: (BuildContext context) => const ImportConflictDialog(),
      );
      if (selected == null) {
        setState(() {
          _importing = false;
        });
        return;
      }
      mode = selected;
    }

    try {
      final ImportExecutionResult result = await _importEngine
          .importFromDoubaoText(
            content,
            tableName: _tableNameController.text.trim(),
            mode: mode,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入成功！共 ${result.importedCount} 门课程')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：$error')));
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.sourceLabel});

  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFF4CC), Color(0xFFFFFBE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14D19B00),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '从教务页跳转过来',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB98500),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '你当前是从 $sourceLabel 的导入流程过来的。先把课表页截图，再点击下方按钮去豆包识别会更顺。',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppTokens.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTokens.textMain,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTokens.duckYellowSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFFB98500),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppTokens.textMain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: AppTokens.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppTokens.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
