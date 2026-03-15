import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_tokens.dart';
import '../data/todo_repository.dart';

class NewTodoPage extends StatefulWidget {
  const NewTodoPage({
    super.key,
    required this.taskTypeLabels,
    this.courseOptions = const <String>[],
  });

  final Map<String, String> taskTypeLabels;
  final List<String> courseOptions;

  @override
  State<NewTodoPage> createState() => _NewTodoPageState();
}

class _NewTodoPageState extends State<NewTodoPage> {
  final TodoRepository _repository = TodoRepository();
  final TextEditingController _titleController = TextEditingController();

  DateTime _dueAt = DateTime.now().add(const Duration(hours: 2));
  String _taskType = 'assignment';
  String? _selectedCourse;
  bool _submitting = false;
  String? _error;

  late final List<(String key, String label)> _taskTypes;
  late final List<String> _courseOptions;

  @override
  void initState() {
    super.initState();
    _taskTypes = widget.taskTypeLabels.entries
        .map((MapEntry<String, String> item) => (item.key, item.value))
        .toList(growable: false);
    _taskType = _taskTypes.isNotEmpty ? _taskTypes.first.$1 : 'assignment';
    _courseOptions = widget.courseOptions.isNotEmpty
        ? <String>[...widget.courseOptions, '更多']
        : const <String>[];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final List<int> years = List<int>.generate(5, (int index) => currentYear - 1 + index);
    final List<int> months = List<int>.generate(12, (int index) => index + 1);
    final List<int> days = List<int>.generate(31, (int index) => index + 1);
    final List<int> hours = List<int>.generate(24, (int index) => index);
    final List<int> minutes = List<int>.generate(12, (int index) => index * 5);

    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTokens.pageBackground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '新建待办',
          style: TextStyle(
            color: AppTokens.textMain,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
        children: <Widget>[
          const Text(
            '计划是什么？',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTokens.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 146,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x22F0D9AA),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _titleController,
              maxLength: 80,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '完成高数第四次习题...',
                counterText: '',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD0C9C2),
                ),
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTokens.textMain,
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '任务类型',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTokens.textMain,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _buildTaskTypePills(),
          ),
          const SizedBox(height: 20),
          if (_courseOptions.isNotEmpty) ...<Widget>[
            const Text(
              '关联课程',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTokens.textMain,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _courseOptions
                  .map((String course) => _SelectPill(
                        text: course,
                        active: _selectedCourse == course,
                        onTap: () async {
                          if (course == '更多') {
                            await _inputCustomCourse();
                            return;
                          }
                          setState(() {
                            _selectedCourse = course;
                          });
                        },
                      ))
                  .toList(growable: false),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            '截止日期',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTokens.textMain,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '年月日',
            style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
          ),
          const SizedBox(height: 8),
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1AF0D9AA),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _WheelNumberPicker(
                    values: years,
                    selectedValue: _dueAt.year,
                    labelBuilder: (int value) => '$value',
                    onSelected: (int value) => _setDateParts(year: value),
                  ),
                ),
                Expanded(
                  child: _WheelNumberPicker(
                    values: months,
                    selectedValue: _dueAt.month,
                    labelBuilder: (int value) => value.toString().padLeft(2, '0'),
                    onSelected: (int value) => _setDateParts(month: value),
                  ),
                ),
                Expanded(
                  child: _WheelNumberPicker(
                    values: days,
                    selectedValue: _dueAt.day,
                    labelBuilder: (int value) => value.toString().padLeft(2, '0'),
                    onSelected: (int value) => _setDateParts(day: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '截止时间',
            style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
          ),
          const SizedBox(height: 6),
          Container(
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1AF0D9AA),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _WheelNumberPicker(
                    values: hours,
                    selectedValue: _dueAt.hour,
                    labelBuilder: (int value) => value.toString().padLeft(2, '0'),
                    onSelected: (int value) => _setTimeParts(hour: value),
                  ),
                ),
                const Text(
                  ':',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textMain,
                  ),
                ),
                Expanded(
                  child: _WheelNumberPicker(
                    values: minutes,
                    selectedValue: _nearestMinute(_dueAt.minute),
                    labelBuilder: (int value) => value.toString().padLeft(2, '0'),
                    onSelected: (int value) => _setTimeParts(minute: value),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFD64545), fontSize: 12),
            ),
          ],
          const SizedBox(height: 26),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFFF7CC57),
              foregroundColor: AppTokens.textMain,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('添加待办'),
          ),
        ],
      ),
    );
  }

  void _setDateParts({int? year, int? month, int? day}) {
    final int targetYear = year ?? _dueAt.year;
    final int targetMonth = month ?? _dueAt.month;
    final int targetDay = day ?? _dueAt.day;
    final int safeDay = targetDay.clamp(1, DateUtils.getDaysInMonth(targetYear, targetMonth));
    setState(() {
      _dueAt = DateTime(targetYear, targetMonth, safeDay, _dueAt.hour, _dueAt.minute);
    });
  }

  void _setTimeParts({int? hour, int? minute}) {
    setState(() {
      _dueAt = DateTime(
        _dueAt.year,
        _dueAt.month,
        _dueAt.day,
        hour ?? _dueAt.hour,
        minute ?? _dueAt.minute,
      );
    });
  }

  int _nearestMinute(int minute) {
    final int raw = ((minute / 5).round() * 5) % 60;
    return raw;
  }

  List<Widget> _buildTaskTypePills() {
    final List<(String key, String label)> visible = _taskTypes.take(3).toList(growable: false);
    if (_taskTypes.length > 3 && !visible.any((item) => item.$1 == _taskType)) {
      final (String key, String label) selected =
          _taskTypes.firstWhere((item) => item.$1 == _taskType, orElse: () => _taskTypes.first);
      visible[2] = selected;
    }

    final List<Widget> widgets = visible
        .map((option) => _SelectPill(
              text: option.$2,
              active: _taskType == option.$1,
              onTap: () {
                setState(() {
                  _taskType = option.$1;
                });
              },
            ))
        .toList(growable: true);

    if (_taskTypes.length > 3) {
      widgets.add(
        _SelectPill(
          text: '...',
          active: false,
          onTap: _openTaskTypeSelector,
        ),
      );
    }

    return widgets;
  }

  Future<void> _openTaskTypeSelector() async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(
                  child: Text(
                    '选择任务类型',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTokens.textMain),
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in _taskTypes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.$2),
                    trailing: option.$1 == _taskType
                        ? const Icon(Icons.check_circle, color: AppTokens.duckYellow)
                        : null,
                    onTap: () => Navigator.of(context).pop(option.$1),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _taskType = picked;
      });
    }
  }

  Future<void> _inputCustomCourse() async {
    // “更多”入口允许用户补录课程，避免关联课程被固定选项限制。
    final TextEditingController controller = TextEditingController();
    final String? course = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('输入课程名称'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '例如：专业英语'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (course == null || course.isEmpty) {
      return;
    }

    setState(() {
      _selectedCourse = course;
    });
  }

  Future<void> _submit() async {
    // 提交前做最小必填校验，避免写入无意义记录。
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _error = '请先填写计划内容。';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _repository.addTodo(
        title: title,
        taskType: _taskType,
        courseName: _selectedCourse,
        dueAt: _dueAt,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }
}

class _SelectPill extends StatelessWidget {
  const _SelectPill({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFFFF2C9) : const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (active) ...<Widget>[
                const Icon(Icons.check, size: 14, color: Color(0xFFB98500)),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? AppTokens.textMain : const Color(0xFF7F7A74),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelNumberPicker extends StatelessWidget {
  const _WheelNumberPicker({
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<int> values;
  final int selectedValue;
  final String Function(int value) labelBuilder;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = values.indexOf(selectedValue).clamp(0, values.length - 1);
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: selectedIndex),
      itemExtent: 34,
      looping: true,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          color: const Color(0x12FFD769),
          border: Border.symmetric(
            horizontal: BorderSide(color: Color(0x44FFD769)),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onSelectedItemChanged: (int index) {
        onSelected(values[index]);
      },
      children: values
          .map<Widget>(
            (int value) => Center(
              child: Text(
                labelBuilder(value),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.textMain,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
