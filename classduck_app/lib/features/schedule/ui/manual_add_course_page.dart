import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_tokens.dart';
import '../data/schedule_repository.dart';
import '../domain/course.dart';
import '../domain/course_table.dart';
import 'manual_more_colors_page.dart';

class ManualCourseSessionPrefill {
  const ManualCourseSessionPrefill({
    required this.weekday,
    required this.startPeriod,
    required this.endPeriod,
    this.startWeek = 1,
    this.endWeek = 16,
    this.colorHex,
  });

  final int weekday;
  final int startPeriod;
  final int endPeriod;
  final int startWeek;
  final int endWeek;
  final String? colorHex;
}

class ManualCoursePrefill {
  const ManualCoursePrefill({required this.sessions});

  final List<ManualCourseSessionPrefill> sessions;
}

class ManualAddCoursePage extends StatefulWidget {
  const ManualAddCoursePage({super.key, this.prefill});

  final ManualCoursePrefill? prefill;

  @override
  State<ManualAddCoursePage> createState() => _ManualAddCoursePageState();
}

class _ManualAddCoursePageState extends State<ManualAddCoursePage> {
  final ScheduleRepository _repository = ScheduleRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();

  final List<_SessionDraft> _sessions = <_SessionDraft>[];
  int _colorLookupToken = 0;
  bool _saving = false;

  static const int _maxPeriod = 10;
  static const int _maxWeek = 20;

  static const List<String> _baseQuickColors = <String>[
    '#D45E6A',
    '#CBA42F',
    '#4A88D2',
    '#B6C223',
    '#896ED8',
  ];

  @override
  void initState() {
    super.initState();
    _seedSessionsFromPrefill();
    _nameController.addListener(_onCourseNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onCourseNameChanged);
    _nameController.dispose();
    _locationController.dispose();
    _teacherController.dispose();
    for (final _SessionDraft draft in _sessions) {
      draft.dispose();
    }
    super.dispose();
  }

  void _seedSessionsFromPrefill() {
    final List<ManualCourseSessionPrefill> prefill =
        widget.prefill?.sessions ?? const <ManualCourseSessionPrefill>[];

    if (prefill.isEmpty) {
      _sessions.add(
        _SessionDraft.fromPrefill(
          const ManualCourseSessionPrefill(
            weekday: 1,
            startPeriod: 1,
            endPeriod: 2,
            startWeek: 1,
            endWeek: 16,
          ),
        ),
      );
      return;
    }

    _sessions.addAll(prefill.map(_SessionDraft.fromPrefill));
  }

  void _onCourseNameChanged() {
    _applyBaseColorFromExisting();
  }

  Future<void> _applyBaseColorFromExisting() async {
    if (_sessions.isEmpty) {
      return;
    }

    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final int ticket = ++_colorLookupToken;
    final String? baseColor = await _repository.getManualCourseBaseColor(name);
    if (!mounted ||
        ticket != _colorLookupToken ||
        baseColor == null ||
        baseColor.isEmpty) {
      return;
    }

    bool changed = false;
    for (final _SessionDraft session in _sessions) {
      changed = session.applyAutoColor(baseColor) || changed;
    }

    if (changed) {
      setState(() {});
    }
  }

  bool _sessionPeriodError(_SessionDraft session) {
    final int? start = int.tryParse(session.startPeriodController.text.trim());
    final int? end = int.tryParse(session.endPeriodController.text.trim());
    if (start == null || end == null) {
      return true;
    }
    if (start <= 0 || end <= 0 || start > end) {
      return true;
    }
    if (start > _maxPeriod || end > _maxPeriod) {
      return true;
    }
    return false;
  }

  bool _sessionWeekError(_SessionDraft session) {
    final int? start = int.tryParse(session.startWeekController.text.trim());
    final int? end = int.tryParse(session.endWeekController.text.trim());
    if (start == null || end == null) {
      return true;
    }
    if (start <= 0 || end <= 0 || start > end) {
      return true;
    }
    if (start > _maxWeek || end > _maxWeek) {
      return true;
    }
    return false;
  }

  void _addSession() {
    if (_sessions.isEmpty) {
      return;
    }
    setState(() {
      _sessions.add(_sessions.last.copyForAppend());
    });
  }

  Future<void> _pickMoreColor(int index) async {
    final String current = _sessions[index].selectedColor;
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                  children: ManualMoreColorsPage.palette
                      .map((String colorHex) {
                        final bool selected = colorHex == current;
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
                      })
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _sessions[index].selectColor(selected, markUserSelected: true);
    });
  }

  Future<int> _resolveTargetTableId() async {
    List<CourseTableEntity> tables = await _repository.getCourseTables();
    if (tables.isEmpty) {
      await _repository.createCourseTable(name: '手动课表');
      tables = await _repository.getCourseTables();
    }

    final int? activeTableId = ScheduleRepository.activeTableId;
    if (activeTableId != null &&
        tables.any((CourseTableEntity item) => item.id == activeTableId)) {
      return activeTableId;
    }

    final int tableId = tables.first.id!;
    _repository.setActiveTableId(tableId);
    return tableId;
  }

  Future<void> _saveCourses() async {
    final String name = _nameController.text.trim();
    final String location = _locationController.text.trim();
    final String teacher = _teacherController.text.trim();

    if (name.isEmpty || location.isEmpty) {
      _showError('请填写课程名称和上课地点');
      return;
    }

    for (int i = 0; i < _sessions.length; i++) {
      final _SessionDraft session = _sessions[i];
      if (_sessionPeriodError(session)) {
        _showError('第${i + 1}组的上课节次不合法');
        return;
      }
      if (_sessionWeekError(session)) {
        _showError('第${i + 1}组的上课周数不合法');
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      final int tableId = await _resolveTargetTableId();
      final String now = DateTime.now().toUtc().toIso8601String();

      final List<CourseEntity> courses = <CourseEntity>[
        for (final _SessionDraft session in _sessions)
          CourseEntity(
            tableId: tableId,
            name: name,
            classroom: location,
            teacher: teacher.isEmpty ? null : teacher,
            weeksJson: jsonEncode(session.weeks),
            weekTime: session.weekday,
            startTime: session.startPeriod,
            timeCount: session.endPeriod - session.startPeriod + 1,
            importType: 0,
            colorHex: session.selectedColor,
            createdAt: now,
            updatedAt: now,
          ),
      ];

      await _repository.addCourses(tableId: tableId, courses: courses);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      _showError('新建失败：$error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final double safeBottom = MediaQuery.of(context).padding.bottom;
    final double actionBottom = bottomInset > 0
        ? bottomInset + 12
        : safeBottom + 12;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('手动添加'),
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 136 + bottomInset),
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
              const SizedBox(height: 14),
              for (int i = 0; i < _sessions.length; i++) ...<Widget>[
                _SessionCard(
                  index: i,
                  draft: _sessions[i],
                  deletable: i > 0,
                  periodError: _sessionPeriodError(_sessions[i]),
                  weekError: _sessionWeekError(_sessions[i]),
                  onWeekdayChanged: (int value) {
                    setState(() {
                      _sessions[i].weekday = value;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      _sessions[i].dispose();
                      _sessions.removeAt(i);
                    });
                  },
                  onQuickColorTap: (String color) {
                    setState(() {
                      _sessions[i].selectColor(color, markUserSelected: true);
                    });
                  },
                  onMoreColorTap: () => _pickMoreColor(i),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _addSession,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppTokens.duckYellow),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppTokens.duckYellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '新增节次',
                        style: TextStyle(
                          color: AppTokens.duckYellow,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: actionBottom,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.duckYellow,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saving ? null : _saveCourses,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '新建课程',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
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

class _SessionDraft {
  _SessionDraft({
    required this.weekday,
    required this.startPeriodController,
    required this.endPeriodController,
    required this.startWeekController,
    required this.endWeekController,
    required this.quickColors,
    required this.selectedColor,
    required this.userSelectedColor,
  });

  factory _SessionDraft.fromPrefill(ManualCourseSessionPrefill prefill) {
    final String initialColor =
        prefill.colorHex ?? _ManualAddCoursePageState._baseQuickColors.first;
    final List<String> quickColors = _promoteColor(
      List<String>.from(_ManualAddCoursePageState._baseQuickColors),
      initialColor,
    );

    return _SessionDraft(
      weekday: prefill.weekday.clamp(1, 7).toInt(),
      startPeriodController: TextEditingController(
        text: prefill.startPeriod.toString(),
      ),
      endPeriodController: TextEditingController(
        text: prefill.endPeriod.toString(),
      ),
      startWeekController: TextEditingController(
        text: prefill.startWeek.toString(),
      ),
      endWeekController: TextEditingController(
        text: prefill.endWeek.toString(),
      ),
      quickColors: quickColors,
      selectedColor: initialColor,
      userSelectedColor: prefill.colorHex != null,
    );
  }

  int weekday;
  final TextEditingController startPeriodController;
  final TextEditingController endPeriodController;
  final TextEditingController startWeekController;
  final TextEditingController endWeekController;
  List<String> quickColors;
  String selectedColor;
  bool userSelectedColor;

  int get startPeriod => int.tryParse(startPeriodController.text.trim()) ?? 1;
  int get endPeriod =>
      int.tryParse(endPeriodController.text.trim()) ?? startPeriod;
  int get startWeek => int.tryParse(startWeekController.text.trim()) ?? 1;
  int get endWeek => int.tryParse(endWeekController.text.trim()) ?? startWeek;

  List<int> get weeks => <int>[for (int i = startWeek; i <= endWeek; i++) i];

  bool applyAutoColor(String colorHex) {
    if (userSelectedColor) {
      return false;
    }
    final bool changed = selectedColor != colorHex;
    selectedColor = colorHex;
    quickColors = _promoteColor(quickColors, colorHex);
    return changed;
  }

  void selectColor(String colorHex, {required bool markUserSelected}) {
    selectedColor = colorHex;
    quickColors = _promoteColor(quickColors, colorHex);
    if (markUserSelected) {
      userSelectedColor = true;
    }
  }

  _SessionDraft copyForAppend() {
    return _SessionDraft(
      weekday: weekday,
      startPeriodController: TextEditingController(
        text: startPeriodController.text.trim(),
      ),
      endPeriodController: TextEditingController(
        text: endPeriodController.text.trim(),
      ),
      startWeekController: TextEditingController(
        text: startWeekController.text.trim(),
      ),
      endWeekController: TextEditingController(
        text: endWeekController.text.trim(),
      ),
      quickColors: List<String>.from(quickColors),
      selectedColor: selectedColor,
      userSelectedColor: userSelectedColor,
    );
  }

  void dispose() {
    startPeriodController.dispose();
    endPeriodController.dispose();
    startWeekController.dispose();
    endWeekController.dispose();
  }

  static List<String> _promoteColor(List<String> source, String colorHex) {
    final List<String> next = <String>[...source];
    next.remove(colorHex);
    next.insert(0, colorHex);
    return next.take(5).toList(growable: true);
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.index,
    required this.draft,
    required this.deletable,
    required this.periodError,
    required this.weekError,
    required this.onWeekdayChanged,
    required this.onDelete,
    required this.onQuickColorTap,
    required this.onMoreColorTap,
  });

  final int index;
  final _SessionDraft draft;
  final bool deletable;
  final bool periodError;
  final bool weekError;
  final ValueChanged<int> onWeekdayChanged;
  final VoidCallback onDelete;
  final ValueChanged<String> onQuickColorTap;
  final VoidCallback onMoreColorTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '节次配置 ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textMain,
                ),
              ),
              const Spacer(),
              if (deletable)
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFE16C7B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('星期', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _WeekdaySingleLine(value: draft.weekday, onChanged: onWeekdayChanged),
          const SizedBox(height: 10),
          _RangeInputRow(
            title: '上课节次',
            startController: draft.startPeriodController,
            endController: draft.endPeriodController,
            error: periodError,
          ),
          if (periodError)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '节次不合法或超出当日总节次上限',
                style: TextStyle(color: Color(0xFFE16C7B), fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          _RangeInputRow(
            title: '上课周数',
            startController: draft.startWeekController,
            endController: draft.endWeekController,
            error: weekError,
          ),
          if (weekError)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '周数不合法或超出学期周数上限',
                style: TextStyle(color: Color(0xFFE16C7B), fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          const Text('卡片颜色', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              for (final String colorHex in draft.quickColors) ...<Widget>[
                _ColorChip(
                  colorHex: colorHex,
                  selected: colorHex == draft.selectedColor,
                  onTap: () => onQuickColorTap(colorHex),
                ),
                const SizedBox(width: 8),
              ],
              _MoreColorChip(onTap: onMoreColorTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdaySingleLine extends StatelessWidget {
  const _WeekdaySingleLine({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(7, (int index) {
        final int day = index + 1;
        final bool active = value == day;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(day),
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? AppTokens.duckYellowSoft
                      : const Color(0xFFF5F1E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? const Color(0xFFD89B00)
                        : const Color(0xFFE8DFD2),
                  ),
                ),
                child: Text(
                  '周${_ManualAddCoursePageState._weekdayText(day)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? const Color(0xFFD89B00)
                        : AppTokens.textMain,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.colorHex,
    required this.selected,
    required this.onTap,
  });

  final String colorHex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _ManualAddCoursePageState._parseColor(colorHex),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected ? const Color(0xFFD89B00) : const Color(0xFFE8DFD2),
          ),
        ),
      ),
    );
  }
}

class _MoreColorChip extends StatelessWidget {
  const _MoreColorChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F1E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8DFD2)),
        ),
        child: const Text(
          '更多',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTokens.textMain,
          ),
        ),
      ),
    );
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
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppTokens.textMuted),
          ),
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
