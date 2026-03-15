import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_tokens.dart';
import '../data/schedule_repository.dart';
import '../domain/course.dart';
import '../domain/course_table.dart';
import 'manual_more_colors_page.dart';

class ManualAddCoursePage extends StatefulWidget {
  const ManualAddCoursePage({super.key});

  @override
  State<ManualAddCoursePage> createState() => _ManualAddCoursePageState();
}

class _ManualAddCoursePageState extends State<ManualAddCoursePage> {
  final ScheduleRepository _repository = ScheduleRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _startPeriodController = TextEditingController(text: '1');
  final TextEditingController _endPeriodController = TextEditingController(text: '2');
  final TextEditingController _startWeekController = TextEditingController(text: '1');
  final TextEditingController _endWeekController = TextEditingController(text: '16');

  int _weekday = 1;
  String? _selectedColor = '#FFE6EA';
  bool _saving = false;

  static const int _maxPeriod = 10;
  static const int _maxWeek = 20;

  static const List<String> _colorPalette = <String>[
    '#FFE6EA',
    '#E5F7EA',
    '#E5F1FF',
    '#F1E7FF',
    '#FFF4CC',
    '#FFD8B8',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _teacherController.dispose();
    _startPeriodController.dispose();
    _endPeriodController.dispose();
    _startWeekController.dispose();
    _endWeekController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool periodRangeError = _isPeriodRangeError;
    final bool weekRangeError = _isWeekRangeError;

    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('手动添加'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: <Widget>[
          _InputCard(
            title: '课程名称',
            controller: _nameController,
            hintText: '例如：高等数学',
          ),
          const SizedBox(height: 10),
          _InputCard(
            title: '上课地点',
            controller: _locationController,
            hintText: '例如：教1-304',
          ),
          const SizedBox(height: 10),
          _InputCard(
            title: '任课教师（可选）',
            controller: _teacherController,
            hintText: '例如：李老师',
          ),
          const SizedBox(height: 12),
          const Text('星期', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(7, (int index) {
              final int day = index + 1;
              final bool active = _weekday == day;
              return ChoiceChip(
                label: Text('周${_weekdayText(day)}'),
                selected: active,
                selectedColor: AppTokens.duckYellowSoft,
                labelStyle: TextStyle(
                  color: active ? const Color(0xFFD89B00) : AppTokens.textMain,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (_) {
                  setState(() {
                    _weekday = day;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 14),
          _RangeInputRow(
            title: '上课节次',
            startController: _startPeriodController,
            endController: _endPeriodController,
            error: periodRangeError,
          ),
          if (periodRangeError)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '节次不合法或超出当日总节次上限',
                style: TextStyle(color: Color(0xFFE16C7B), fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          _RangeInputRow(
            title: '上课周数',
            startController: _startWeekController,
            endController: _endWeekController,
            error: weekRangeError,
          ),
          if (weekRangeError)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '周数不合法或超出学期周数上限',
                style: TextStyle(color: Color(0xFFE16C7B), fontSize: 12),
              ),
            ),
          const SizedBox(height: 14),
          const Text('卡片颜色', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colorPalette.map((String color) {
              final bool selected = _selectedColor == color;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _parseColor(color),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      width: selected ? 2 : 1,
                      color: selected ? const Color(0xFFD89B00) : const Color(0xFFE8DFD2),
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _openMoreColors,
              child: const Text('更多 ...'),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.duckYellow,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _saving ? null : _saveCourse,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存课程', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isPeriodRangeError {
    final int? start = int.tryParse(_startPeriodController.text.trim());
    final int? end = int.tryParse(_endPeriodController.text.trim());

    if (start == null || end == null) return true;
    if (start <= 0 || end <= 0 || start > end) return true;
    if (start > _maxPeriod || end > _maxPeriod) return true;
    return false;
  }

  bool get _isWeekRangeError {
    final int? start = int.tryParse(_startWeekController.text.trim());
    final int? end = int.tryParse(_endWeekController.text.trim());

    if (start == null || end == null) return true;
    if (start <= 0 || end <= 0 || start > end) return true;
    if (start > _maxWeek || end > _maxWeek) return true;
    return false;
  }

  Future<void> _saveCourse() async {
    final String name = _nameController.text.trim();
    final String location = _locationController.text.trim();

    if (name.isEmpty || location.isEmpty || _selectedColor == null) {
      _showError('请填写必填项后再保存');
      return;
    }

    if (_isPeriodRangeError || _isWeekRangeError) {
      _showError('请先修正节次或周数输入');
      return;
    }

    final int startPeriod = int.parse(_startPeriodController.text.trim());
    final int endPeriod = int.parse(_endPeriodController.text.trim());
    final int startWeek = int.parse(_startWeekController.text.trim());
    final int endWeek = int.parse(_endWeekController.text.trim());

    setState(() {
      _saving = true;
    });

    try {
      List<CourseTableEntity> tables = await _repository.getCourseTables();
      if (tables.isEmpty) {
        await _repository.createCourseTable(name: '手动课表');
        tables = await _repository.getCourseTables();
      }

      final int tableId = tables.first.id!;
      final String now = DateTime.now().toUtc().toIso8601String();
      final List<int> weeks = <int>[for (int i = startWeek; i <= endWeek; i++) i];

      await _repository.addCourses(
        tableId: tableId,
        courses: <CourseEntity>[
          CourseEntity(
            tableId: tableId,
            name: name,
            classroom: location,
            teacher: _teacherController.text.trim().isEmpty
                ? null
                : _teacherController.text.trim(),
            weeksJson: jsonEncode(weeks),
            weekTime: _weekday,
            startTime: startPeriod,
            timeCount: endPeriod - startPeriod + 1,
            importType: 0,
            colorHex: _selectedColor,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      _showError('保存失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _openMoreColors() async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  '更多颜色',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textMain,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ManualMoreColorsPage.palette.map((String colorHex) {
                    final bool selected = colorHex == _selectedColor;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(colorHex),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _parseColor(colorHex),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            width: selected ? 2 : 1,
                            color: selected
                                ? const Color(0xFFD89B00)
                                : const Color(0xFFE8DFD2),
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedColor = selected;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _weekdayText(int day) {
    switch (day) {
      case 1:
        return '一';
      case 2:
        return '二';
      case 3:
        return '三';
      case 4:
        return '四';
      case 5:
        return '五';
      case 6:
        return '六';
      default:
        return '日';
    }
  }

  static Color _parseColor(String hex) {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.title,
    required this.controller,
    required this.hintText,
  });

  final String title;
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 12, color: AppTokens.textMuted)),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeInputRow extends StatelessWidget {
  const _RangeInputRow({
    required this.title,
    required this.startController,
    required this.endController,
    required this.error,
  });

  final String title;
  final TextEditingController startController;
  final TextEditingController endController;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final Border border = Border.all(
      color: error ? const Color(0xFFE16C7B) : const Color(0xFFE8DFD2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: border,
                ),
                child: TextField(
                  controller: startController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('-'),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: border,
                ),
                child: TextField(
                  controller: endController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
