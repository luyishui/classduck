import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';

import '../../import/data/school_config_repository.dart';
import '../../import/domain/school_config.dart';
import '../../import/ui/import_school_list_page.dart';
import '../../settings/data/appearance_state.dart';
import '../../todo/data/todo_repository.dart';
import '../../todo/domain/todo_item.dart';
import '../data/schedule_repository.dart';
import '../domain/course.dart';
import '../domain/course_table.dart';
import 'manual_add_course_page.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/duck_modal.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final SchoolConfigRepository _configRepository = SchoolConfigRepository();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final TodoRepository _todoRepository = TodoRepository();

  bool _loadingConfig = false;
  String? _configError;
  int _schoolConfigCount = 0;

  bool _loadingSchedule = false;
  String? _scheduleError;
  int? _activeTableId;
  bool _addMenuOpen = false;
  int _expandedSidebarGroup = 0;
  String _activeTableName = '我的课表';
  List<CourseEntity> _courses = const <CourseEntity>[];
  int _currentWeek = 1;
  int _displayWeek = 1;
  final Map<int, _ScheduleConfig> _tableConfigs = <int, _ScheduleConfig>{};
  final GlobalKey _gridAreaKey = GlobalKey();
  _QuickAddSelection? _quickAddSelection;
  _CourseDragPayload? _activeCourseDrag;
  _CourseDragHover? _courseDragHover;
  String? _courseDragRejectMessage;
  double _gridColWidth = 0;
  double _gridRowHeight = 0;

  final List<String> _periodTimes = <String>[
    '8:00\n-8:45',
    '8:55\n-9:40',
    '10:00\n-10:45',
    '11:00\n-11:45',
    '14:00\n-14:45',
    '15:00\n-15:45',
    '16:00\n-16:45',
    '17:00\n-17:45',
    '19:00\n-19:45',
    '19:55\n-20:40',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadSchoolConfigs();
    await _loadScheduleData();
  }

  Future<void> _loadSchoolConfigs() async {
    setState(() {
      _loadingConfig = true;
      _configError = null;
    });

    try {
      final List<SchoolConfig> configs =
          await _configRepository.fetchSchoolConfigs();
      setState(() {
        _schoolConfigCount = configs.length;
      });
    } catch (error) {
      setState(() {
        _configError = error.toString();
      });
    } finally {
      setState(() {
        _loadingConfig = false;
      });
    }
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _loadingSchedule = true;
      _scheduleError = null;
    });

    try {
      final List<CourseTableEntity> tables = await _scheduleRepository
          .getCourseTables()
          .timeout(const Duration(seconds: 6));

      if (tables.isEmpty) {
        setState(() {
          _activeTableName = '未选择课表';
          _activeTableId = null;
          _courses = const <CourseEntity>[];
        });
        _scheduleRepository.setActiveTableId(null);
        return;
      }

      final CourseTableEntity active = tables.first;
      final List<CourseEntity> courses = await _scheduleRepository
          .getCoursesByTableId(active.id!)
          .timeout(const Duration(seconds: 6));

      final _ScheduleConfig config = _decodeConfig(active.classTimeListJson);
      _tableConfigs[active.id!] = config;
      _applyConfigToTimeline(config);
      _currentWeek = _computeCurrentWeek(config);
      _displayWeek = _currentWeek <= 0 ? 1 : _currentWeek;

      setState(() {
        _activeTableId = active.id;
        _activeTableName = active.name;
        _courses = courses;
      });
      _scheduleRepository.setActiveTableId(active.id);
    } catch (error) {
      setState(() {
        _scheduleError = '课表加载失败：$error';
        _activeTableName = '课表加载失败';
        _courses = const <CourseEntity>[];
      });
    } finally {
      setState(() {
        _loadingSchedule = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final _ScheduleConfig config = _activeConfig();
    final bool semesterEnded = _isSemesterEnded(config);
    final String dateText = DateFormat('yyyy年M月d日').format(now);
    final int viewingWeek = _effectiveDisplayWeek(config);
    final List<DateTime> weekDates = _weekDatesForDisplay(config, viewingWeek);
    final String weekText = _currentWeek <= 0
        ? '未开学'
        : (semesterEnded ? '已结束' : '第 $viewingWeek 周');
    final bool viewingOtherWeek = _currentWeek > 0 && !semesterEnded && viewingWeek != _currentWeek;
    final double screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 5;

    return ValueListenableBuilder<AppearanceState>(
      valueListenable: AppearanceStore.state,
      builder: (BuildContext context, AppearanceState appearance, Widget? child) {
        return Container(
          color: AppTokens.pageBackground,
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 5, horizontalPadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _TopActionButton(
                            icon: Icons.menu,
                            onTap: _openScheduleSidebar,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  weekText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: viewingOtherWeek
                                        ? const Color(0xFFD64545)
                                        : AppTokens.textMain,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '$dateText ${_weekDayName(now.weekday)}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTokens.textMuted,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          _TopActionButton(
                            icon: Icons.share_outlined,
                            onTap: () {
                              DuckModal.show<void>(
                                context: context,
                                child: const DuckModalFrame(
                                  title: '分享上课鸭',
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: AppTokens.space12),
                                    child: Text('分享 App 链路将在后续任务接入。'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _WeekHeader(
                        weekDates: weekDates,
                        weekStartDay: config.weekStartDay,
                        cornerLabel: '${weekDates.first.month}月',
                        leftSpacing: screenWidth < 380 ? 30 : 32,
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: GestureDetector(
                          onHorizontalDragEnd: (DragEndDetails details) {
                            final double velocity = details.primaryVelocity ?? 0;
                            if (velocity.abs() < 150) {
                              return;
                            }
                            if (velocity < 0) {
                              _shiftDisplayWeek(1);
                            } else {
                              _shiftDisplayWeek(-1);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              image: appearance.backgroundBytes == null
                                  ? null
                                  : DecorationImage(
                                      image: MemoryImage(appearance.backgroundBytes!),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            child: _buildScheduleGrid(),
                          ),
                        ),
                      ),
                      if (_loadingConfig ||
                          _loadingSchedule ||
                          _configError != null ||
                          _scheduleError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _buildStatusLine(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTokens.textMuted,
                                ),
                          ),
                        ),
                      if (!_loadingSchedule && _courses.isEmpty && _scheduleError == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            '当前还没有课程，点击右下角 + 开始导入或手动添加。',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTokens.textMuted,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_addMenuOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _addMenuOpen = false;
                        });
                      },
                      child: Container(color: const Color(0x33000000)),
                    ),
                  ),
                if (_addMenuOpen)
                  Positioned(
                    right: AppTokens.space20,
                    bottom: 148,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        _AddMenuItem(
                          icon: Icons.edit_note_rounded,
                          iconColor: const Color(0xFF93C5FD),
                          title: '手动添加',
                          onTap: () => _handleAddMenuAction('manual'),
                        ),
                        const SizedBox(height: 10),
                        _AddMenuItem(
                          icon: Icons.cloud_sync_outlined,
                          iconColor: const Color(0xFFF59EBC),
                          title: '教务添加',
                          onTap: () => _handleAddMenuAction('import'),
                        ),
                        const SizedBox(height: 10),
                        _AddMenuItem(
                          icon: Icons.photo_camera_outlined,
                          iconColor: const Color(0xFF86EFAC),
                          title: '拍照添加',
                          onTap: () => _handleAddMenuAction('camera'),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  right: AppTokens.space20,
                  bottom: 94,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (viewingOtherWeek && _currentWeek > 0)
                        _RoundAddButton(
                          onTap: _resetDisplayWeekToCurrent,
                          backgroundColor: const Color(0xFFD64545),
                          child: const Icon(Icons.reply_rounded, color: Colors.white, size: 24),
                        ),
                      if (viewingOtherWeek && _currentWeek > 0)
                        const SizedBox(height: 20),
                      _RoundAddButton(
                        onTap: _openAddMenu,
                        child: AnimatedRotation(
                          turns: _addMenuOpen ? 0.125 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(Icons.add, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddMenu() async {
    _clearQuickAddSelection();
    setState(() {
      _addMenuOpen = !_addMenuOpen;
    });
  }

  Future<void> _handleAddMenuAction(String action) async {
    _clearQuickAddSelection();
    setState(() {
      _addMenuOpen = false;
    });

    if (!mounted) {
      return;
    }

    // 统一路由分发：保证任一路径完成后都能刷新课表数据。
    if (action == 'import') {
      final bool? imported = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (BuildContext context) => const ImportSchoolListPage(),
        ),
      );
      if (imported == true) {
        await _loadScheduleData();
      }
    } else if (action == 'manual') {
      final bool? saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (BuildContext context) => const ManualAddCoursePage(),
        ),
      );
      if (saved == true) {
        await _loadScheduleData();
      }
    } else if (action == 'camera') {
      await _handleCameraAdd();
    }
  }

  void _clearQuickAddSelection() {
    if (!mounted) {
      return;
    }
    setState(() {
      _quickAddSelection = null;
    });
  }

  void _showQuickAddSelectionForCell({
    required int dayColumn,
    required int period,
  }) {
    setState(() {
      _quickAddSelection = _QuickAddSelection(
        anchorDay: dayColumn,
        anchorPeriod: period,
        currentDay: dayColumn,
        currentPeriod: period,
      );
    });
  }

  void _updateQuickAddSelectionFromGlobal(Offset globalPosition) {
    final _QuickAddSelection? current = _quickAddSelection;
    if (current == null || _gridColWidth <= 0 || _gridRowHeight <= 0) {
      return;
    }
    final RenderBox? box = _gridAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }

    final Offset local = box.globalToLocal(globalPosition);
    int dayColumn = (local.dx ~/ _gridColWidth) + 1;
    int period = (local.dy ~/ _gridRowHeight) + 1;
    dayColumn = dayColumn.clamp(1, 7).toInt();
    period = period.clamp(1, _periodTimes.length).toInt();

    if (dayColumn == current.currentDay && period == current.currentPeriod) {
      return;
    }

    setState(() {
      _quickAddSelection = current.copyWith(
        currentDay: dayColumn,
        currentPeriod: period,
      );
    });
  }

  Future<void> _openManualAddFromQuickSelection() async {
    final _QuickAddSelection? selection = _quickAddSelection;
    if (selection == null) {
      return;
    }

    final _ScheduleConfig config = _activeConfig();
    final List<ManualCourseSessionPrefill> sessions = <ManualCourseSessionPrefill>[
      for (int dayColumn = selection.dayStart; dayColumn <= selection.dayEnd; dayColumn++)
        ManualCourseSessionPrefill(
          weekday: _weekdayForColumn(dayColumn, config.weekStartDay),
          startPeriod: selection.periodStart,
          endPeriod: selection.periodEnd,
          startWeek: 1,
          endWeek: 16,
        ),
    ];

    _clearQuickAddSelection();

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ManualAddCoursePage(
          prefill: ManualCoursePrefill(sessions: sessions),
        ),
      ),
    );

    if (saved == true) {
      await _loadScheduleData();
    }
  }

  Future<void> _triggerCourseDragVibration() async {
    try {
      if (!await Vibration.hasVibrator()) {
        return;
      }
      await Vibration.vibrate(duration: 50);
    } catch (_) {
      // Ignore haptic failures on unsupported devices/emulators.
    }
  }

  void _startCourseDrag(_CourseDragPayload payload) {
    _clearQuickAddSelection();
    _triggerCourseDragVibration();
    setState(() {
      _activeCourseDrag = payload;
      _courseDragHover = _CourseDragHover(
        dayColumn: payload.sourceDayColumn,
        periodStart: payload.sourceStart,
      );
      _courseDragRejectMessage = null;
    });
  }

  void _clearCourseDragState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeCourseDrag = null;
      _courseDragHover = null;
      _courseDragRejectMessage = null;
    });
  }

  bool _isPointInsideGrid(Offset globalPosition) {
    final RenderBox? box = _gridAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      return false;
    }
    final Offset local = box.globalToLocal(globalPosition);
    return local.dx >= 0 &&
        local.dy >= 0 &&
        local.dx <= box.size.width &&
        local.dy <= box.size.height;
  }

  bool _weeksOverlap(List<int> dragWeeks, List<int> existingWeeks) {
    if (dragWeeks.isEmpty || existingWeeks.isEmpty) {
      return true;
    }
    final int dragStart = dragWeeks.first;
    final int dragEnd = dragWeeks.last;
    final int existStart = existingWeeks.first;
    final int existEnd = existingWeeks.last;
    return dragStart <= existEnd && dragEnd >= existStart;
  }

  _CourseDropDecision _canDropCourseAt({
    required _CourseDragPayload payload,
    required int targetDayColumn,
    required int targetStartPeriod,
  }) {
    final int targetEndPeriod = targetStartPeriod + payload.timeCount - 1;
    if (targetStartPeriod < 1 || targetEndPeriod > _periodTimes.length) {
      return const _CourseDropDecision(accepted: false);
    }

    final _ScheduleConfig config = _activeConfig();
    final int targetWeekday = _weekdayForColumn(targetDayColumn, config.weekStartDay);

    for (final CourseEntity existing in _courses) {
      if (existing.id != null && existing.id == payload.courseId) {
        continue;
      }
      if (existing.weekTime != targetWeekday) {
        continue;
      }
      final int existingStart = existing.startTime;
      final int existingEnd = existing.startTime + existing.timeCount - 1;
      final bool periodOverlap =
          targetStartPeriod <= existingEnd && targetEndPeriod >= existingStart;
      if (!periodOverlap) {
        continue;
      }

      final List<int> existingWeeks = _parseWeeks(existing.weeksJson);
      if (_weeksOverlap(payload.weeks, existingWeeks)) {
        return const _CourseDropDecision(
          accepted: false,
          message: '目标位置已有课程与该课程周数重叠，无法移动',
        );
      }
    }

    return const _CourseDropDecision(accepted: true);
  }

  Future<void> _applyCourseDragDrop({
    required _CourseDragPayload payload,
    required int targetDayColumn,
    required int targetStartPeriod,
  }) async {
    final _CourseDropDecision decision = _canDropCourseAt(
      payload: payload,
      targetDayColumn: targetDayColumn,
      targetStartPeriod: targetStartPeriod,
    );
    if (!decision.accepted) {
      if (decision.message != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decision.message!)),
        );
      }
      return;
    }

    final int? courseId = payload.courseId;
    if (courseId == null) {
      return;
    }

    final _ScheduleConfig config = _activeConfig();
    final int targetWeekday = _weekdayForColumn(targetDayColumn, config.weekStartDay);
    try {
      await _scheduleRepository.updateCourseDetail(
        courseId: courseId,
        name: payload.course.name,
        weekTime: targetWeekday,
        weeksJson: payload.course.weeksJson,
        startTime: targetStartPeriod,
        timeCount: payload.timeCount,
        teacher: payload.course.teacher,
        classroom: payload.course.classroom,
      );
      await _loadScheduleData();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('课程移动失败：$error')),
        );
      }
    }
  }

  Future<void> _openScheduleSidebar() async {
    if (_loadingSchedule) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('课表加载中，请稍后再试。')),
        );
      }
      return;
    }

    List<CourseTableEntity> tables = const <CourseTableEntity>[];
    try {
      tables = await _scheduleRepository.getCourseTables().timeout(const Duration(seconds: 4));
    } catch (_) {
      tables = const <CourseTableEntity>[];
    }
    if (!mounted) {
      return;
    }

    if (_activeTableId == null && tables.isNotEmpty && tables.first.id != null) {
      await _switchCourseTable(tables.first.id!, tables.first.name);
    }

    final TextEditingController tableNameController = TextEditingController();
    bool creatingTable = false;

    const String morningAfternoonConflictText =
        '您的操作会导致上午课程与下午课程时间冲突，无法完成该操作';
    const String afternoonEveningConflictText =
        '您的操作会导致下午课程与晚上课程时间冲突，无法完成该操作';

    String? morningWarningText;
    String? afternoonWarningText;
    String? eveningWarningText;

    List<int> resolveSegmentBounds(_ScheduleConfig config, int period) {
      if (period <= config.morningEnd) {
        return <int>[0, config.morningEnd - 1];
      }
      if (period <= config.afternoonEnd) {
        return <int>[config.afternoonStart - 1, config.afternoonEnd - 1];
      }
      return <int>[config.eveningStart - 1, config.eveningEnd - 1];
    }

    void applyIntraSegmentAutoAdjust(
      _ScheduleConfig config, {
      required int index,
      required bool start,
      required String picked,
    }) {
      final _SectionTime current = config.sectionAt(index);
      int editedStart = start ? _toMinute(picked) : _toMinute(current.start);
      int editedEnd = start ? editedStart + config.classDuration : _toMinute(picked);

      if (editedEnd <= editedStart) {
        editedStart = editedEnd - config.classDuration;
      }

      config.updateSectionAt(
        index,
        current.copyWith(
          start: _formatMinute(editedStart),
          end: _formatMinute(editedEnd),
        ),
      );

      final int period = index + 1;
      final List<int> segmentBounds = resolveSegmentBounds(config, period);
      final int segmentStartIndex = segmentBounds[0];
      final int segmentEndIndex = segmentBounds[1];

      int backwardCursor = editedStart - config.breakDuration;
      for (int i = index - 1; i >= segmentStartIndex; i--) {
        final int autoEnd = backwardCursor;
        final int autoStart = autoEnd - config.classDuration;
        final _SectionTime section = config.sectionAt(i);
        config.updateSectionAt(
          i,
          section.copyWith(
            start: _formatMinute(autoStart),
            end: _formatMinute(autoEnd),
          ),
        );
        backwardCursor = autoStart - config.breakDuration;
      }

      int forwardCursor = editedEnd + config.breakDuration;
      for (int i = index + 1; i <= segmentEndIndex; i++) {
        final int autoStart = forwardCursor;
        final int autoEnd = autoStart + config.classDuration;
        final _SectionTime section = config.sectionAt(i);
        config.updateSectionAt(
          i,
          section.copyWith(
            start: _formatMinute(autoStart),
            end: _formatMinute(autoEnd),
          ),
        );
        forwardCursor = autoEnd + config.breakDuration;
      }
    }

    String? resolveBoundaryConflictMessage(_ScheduleConfig config, int period) {
      final bool morningConflict = config.hasMorningAfternoonConflict();
      final bool afternoonConflict = config.hasAfternoonEveningConflict();
      if (period <= config.morningEnd) {
        return morningConflict ? morningAfternoonConflictText : null;
      }
      if (period <= config.afternoonEnd) {
        if (morningConflict) {
          return morningAfternoonConflictText;
        }
        if (afternoonConflict) {
          return afternoonEveningConflictText;
        }
        return null;
      }
      return afternoonConflict ? afternoonEveningConflictText : null;
    }

    void setWarningForPeriod(
      StateSetter setModalState,
      _ScheduleConfig config,
      int period,
      String? message,
    ) {
      setModalState(() {
        if (period <= config.morningEnd) {
          morningWarningText = message;
          return;
        }
        if (period <= config.afternoonEnd) {
          afternoonWarningText = message;
          return;
        }
        eveningWarningText = message;
      });
    }

    Future<void> deleteTable(CourseTableEntity table, StateSetter setModalState) async {
      final int? tableId = table.id;
      if (tableId == null) {
        return;
      }
      if (tables.length <= 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('至少保留一张课表，无法删除最后一张。')),
          );
        }
        return;
      }

      await _scheduleRepository.deleteCourseTable(tableId);
      tables = await _scheduleRepository.getCourseTables();

      if (tables.isNotEmpty) {
        final CourseTableEntity fallback = tables.first;
        if (fallback.id != null) {
          await _switchCourseTable(fallback.id!, fallback.name);
        }
      }
      setModalState(() {});
    }

    Future<void> updateConfig(void Function(_ScheduleConfig config) updater) async {
      final int? tableId = _activeTableId;
      if (tableId == null) {
        return;
      }
      final _ScheduleConfig config = _activeConfig();
      updater(config);
      _tableConfigs[tableId] = config;
      _applyConfigToTimeline(config);
      _currentWeek = _computeCurrentWeek(config);
      setState(() {});
      await _persistActiveConfig();
    }

    Future<void> createTable(String name, StateSetter setModalState) async {
      final String trimmed = name.trim();
      if (trimmed.isEmpty || trimmed.length > 20) {
        return;
      }
      final CourseTableEntity table = await _scheduleRepository.createCourseTable(
        name: trimmed,
        semesterStartMonday: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        classTimeList: const <Map<String, String>>[],
      );
      _tableConfigs[table.id!] = _ScheduleConfig.defaults();
      await _scheduleRepository.updateCourseTableConfig(
        tableId: table.id!,
        classTimeListJson: _ScheduleConfig.defaults().toJson(),
        semesterStartMonday: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      tables = await _scheduleRepository.getCourseTables();
      await _switchCourseTable(table.id!, table.name);
      setModalState(() {
        creatingTable = false;
        tableNameController.clear();
      });
    }

    Future<void> pickTime({
      required int index,
      required bool start,
      required StateSetter setModalState,
    }) async {
      final _ScheduleConfig config = _activeConfig();
      if (index < 0 || index >= config.sections.length) {
        return;
      }
      final _SectionTime sourceSection = config.sectionAt(index);
      final String source = start ? sourceSection.start : sourceSection.end;
      final int period = index + 1;

      String? validateSegmentConflict(String picked) {
        final _ScheduleConfig draft = config.clone();
        applyIntraSegmentAutoAdjust(
          draft,
          index: index,
          start: start,
          picked: picked,
        );
        final String? conflictMessage = resolveBoundaryConflictMessage(draft, period);
        if (conflictMessage != null) {
          setWarningForPeriod(setModalState, config, period, conflictMessage);
        }
        return conflictMessage;
      }

      final String? pickedValue = await _openTimeEditDialog(
        context,
        source,
        validator: validateSegmentConflict,
      );
      if (pickedValue == null) {
        return;
      }

      String? blockedMessage;
      await updateConfig((config) {
        final _ScheduleConfig draft = config.clone();
        applyIntraSegmentAutoAdjust(
          draft,
          index: index,
          start: start,
          picked: pickedValue,
        );
        blockedMessage = resolveBoundaryConflictMessage(draft, period);
        if (blockedMessage != null) {
          return;
        }
        config.overwriteFrom(draft);
      });

      setWarningForPeriod(setModalState, _activeConfig(), period, blockedMessage);
    }

    if (!mounted) {
      return;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'schedule-sidebar',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (
        BuildContext dialogContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final _ScheduleConfig config = _activeConfig();
            final bool morningConflict = config.hasMorningAfternoonConflict();
            final bool afternoonConflict = config.hasAfternoonEveningConflict();
            final int maxMorningCount = config.maxMorningCountWithoutConflict();
            final int maxAfternoonCount = config.maxAfternoonCountWithoutConflict();
            final bool disableMorningIncrease = config.morningCount >= maxMorningCount;
            final bool disableAfternoonIncrease = config.afternoonCount >= maxAfternoonCount;

            final String? morningCardWarning =
              morningConflict ? morningAfternoonConflictText : morningWarningText;
            final String? afternoonCardWarning = afternoonConflict
              ? afternoonEveningConflictText
              : (morningConflict ? morningAfternoonConflictText : afternoonWarningText);
            final String? eveningCardWarning =
              afternoonConflict ? afternoonEveningConflictText : eveningWarningText;

            Widget buildSectionEditors(int fromSection, int toSection) {
              return Column(
                children: <Widget>[
                  for (int section = fromSection; section <= toSection; section++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EFE9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            ...() {
                              final int index = section - 1;
                              final _SectionTime sectionTime =
                                  (index >= 0 && index < config.sections.length)
                                      ? config.sections[index]
                                      : const _SectionTime(start: '00:00', end: '00:45');
                              return <Widget>[
                            SizedBox(
                              width: 34,
                              child: Text(
                                '$section节',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.textMain,
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  await pickTime(
                                    index: section - 1,
                                    start: true,
                                    setModalState: setModalState,
                                  );
                                },
                                child: Container(
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7E3DC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sectionTime.start,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppTokens.textMain),
                                  ),
                                ),
                              ),
                            ),
                            const Text('-', style: TextStyle(fontSize: 12, color: AppTokens.textMuted)),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  await pickTime(
                                    index: section - 1,
                                    start: false,
                                    setModalState: setModalState,
                                  );
                                },
                                child: Container(
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7E3DC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sectionTime.end,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppTokens.textMain),
                                  ),
                                ),
                              ),
                            ),
                              ];
                            }(),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }

            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: const Color(0x66000000),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: const Color(0xFFFFFDF6),
                    child: SizedBox(
                      width: 340,
                      child: SafeArea(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const SizedBox(width: 8),
                                const Text(
                                  '上课鸭',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTokens.textMain,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  icon: const Icon(Icons.close, color: AppTokens.textMain),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _SidebarGroupCard(
                              title: '课表设置',
                              icon: Icons.calendar_month,
                              color: const Color(0xFFFFF2C9),
                              expanded: _expandedSidebarGroup == 0,
                              onToggle: () => setModalState(() {
                                _expandedSidebarGroup = _expandedSidebarGroup == 0 ? -1 : 0;
                              }),
                              child: Column(
                                children: <Widget>[
                                  for (final CourseTableEntity table in tables)
                                    InkWell(
                                      onTap: () async {
                                        if (table.id == null) {
                                          return;
                                        }
                                        await _switchCourseTable(table.id!, table.name);
                                        setModalState(() {});
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        child: Row(
                                          children: <Widget>[
                                            const SizedBox(width: 2),
                                            if (table.id == _activeTableId)
                                              const Padding(
                                                padding: EdgeInsets.only(right: 6),
                                                child: Icon(Icons.check_circle, size: 16, color: Color(0xFFB98500)),
                                              )
                                            else
                                              const SizedBox(width: 22),
                                            Expanded(
                                              child: Text(
                                                table.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTokens.textMain,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                              padding: EdgeInsets.zero,
                                              splashRadius: 16,
                                              tooltip: '删除课表',
                                              onPressed: () async => deleteTable(table, setModalState),
                                              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFE16C7B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (creatingTable)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextField(
                                              controller: tableNameController,
                                              maxLength: 20,
                                              decoration: const InputDecoration(
                                                counterText: '',
                                                hintText: '课表名称',
                                                isDense: true,
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => createTable(tableNameController.text, setModalState),
                                            icon: const Icon(Icons.check_circle, color: AppTokens.duckYellow),
                                          ),
                                          IconButton(
                                            onPressed: () => setModalState(() {
                                              creatingTable = false;
                                              tableNameController.clear();
                                            }),
                                            icon: const Icon(Icons.cancel, color: AppTokens.duckYellow),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 10),
                                        child: TextButton(
                                          onPressed: () => setModalState(() {
                                            creatingTable = true;
                                          }),
                                          child: const Text('+ 新建课表'),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            _SidebarGroupCard(
                              title: '时间设置',
                              icon: Icons.access_time,
                              color: const Color(0xFFE7F2FF),
                              expanded: _expandedSidebarGroup == 1,
                              onToggle: () => setModalState(() {
                                _expandedSidebarGroup = _expandedSidebarGroup == 1 ? -1 : 1;
                              }),
                              child: Column(
                                children: <Widget>[
                                  _StepInputRow(
                                    title: '每节课时长',
                                    value: config.classDuration,
                                    min: 10,
                                    max: 180,
                                    buttonColor: const Color(0xFF6D9CD5),
                                    onChanged: (int value) async {
                                      await updateConfig((config) => config.classDuration = value);
                                      setModalState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _StepInputRow(
                                    title: '课间时长',
                                    value: config.breakDuration,
                                    min: 0,
                                    max: 120,
                                    buttonColor: const Color(0xFF6D9CD5),
                                    onChanged: (int value) async {
                                      await updateConfig((config) => config.breakDuration = value);
                                      setModalState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () async {
                                        await updateConfig((config) => config.alignByTemplate());
                                        setModalState(() {});
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF65A5EA),
                                      ),
                                      child: const Text('一键批量对齐'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _SidebarGroupCard(
                              title: '上午课程',
                              icon: Icons.wb_sunny,
                              color: const Color(0xFFFFEDD5),
                              expanded: _expandedSidebarGroup == 2,
                              onToggle: () => setModalState(() {
                                _expandedSidebarGroup = _expandedSidebarGroup == 2 ? -1 : 2;
                              }),
                              child: Column(
                                children: <Widget>[
                                  _StepInputRow(
                                    title: '上午课程节数',
                                    value: config.morningCount,
                                    min: 1,
                                    max: 30,
                                    disableIncrease: disableMorningIncrease,
                                    warningText: morningCardWarning,
                                    dialogMaxValue: maxMorningCount,
                                    dialogConflictMessage: morningAfternoonConflictText,
                                    buttonColor: const Color(0xFFF2A866),
                                    onChanged: (int value) async {
                                      final bool blocked = value > maxMorningCount;
                                      await updateConfig((config) {
                                        final _SegmentAnchors anchors = config.captureAnchors();
                                        final int safeMax = config.maxMorningCountWithoutConflict();
                                        final int safeValue = value
                                            .clamp(1, safeMax)
                                            .toInt();
                                        config.morningCount = safeValue;
                                        config.normalizeCounts();
                                        config.rebuildSectionsByAnchors(anchors);
                                      });
                                      setModalState(() {
                                        morningWarningText = blocked
                                            ? morningAfternoonConflictText
                                            : null;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  buildSectionEditors(1, config.morningEnd),
                                ],
                              ),
                            ),
                            _SidebarGroupCard(
                              title: '下午课程',
                              icon: Icons.wb_cloudy,
                              color: const Color(0xFFFFF5E5),
                              expanded: _expandedSidebarGroup == 3,
                              onToggle: () => setModalState(() {
                                _expandedSidebarGroup = _expandedSidebarGroup == 3 ? -1 : 3;
                              }),
                              child: Column(
                                children: <Widget>[
                                  _StepInputRow(
                                    title: '下午课程节数',
                                    value: config.afternoonCount,
                                    min: 1,
                                    max: 30,
                                    disableIncrease: disableAfternoonIncrease,
                                    warningText: afternoonCardWarning,
                                    dialogMaxValue: maxAfternoonCount,
                                    dialogConflictMessage: afternoonEveningConflictText,
                                    buttonColor: const Color(0xFFE5A15A),
                                    onChanged: (int value) async {
                                      final bool blocked = value > maxAfternoonCount;
                                      await updateConfig((config) {
                                        final _SegmentAnchors anchors = config.captureAnchors();
                                        final int safeMax = config.maxAfternoonCountWithoutConflict();
                                        final int safeValue = value
                                            .clamp(1, safeMax)
                                            .toInt();
                                        config.afternoonCount = safeValue;
                                        config.normalizeCounts();
                                        config.rebuildSectionsByAnchors(anchors);
                                      });
                                      setModalState(() {
                                        afternoonWarningText = blocked
                                            ? afternoonEveningConflictText
                                            : null;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  buildSectionEditors(config.afternoonStart, config.afternoonEnd),
                                ],
                              ),
                            ),
                            _SidebarGroupCard(
                              title: '晚上课程',
                              icon: Icons.dark_mode,
                              color: const Color(0xFFFFE9EF),
                              expanded: _expandedSidebarGroup == 4,
                              onToggle: () => setModalState(() {
                                _expandedSidebarGroup = _expandedSidebarGroup == 4 ? -1 : 4;
                              }),
                              child: Column(
                                children: <Widget>[
                                  _StepInputRow(
                                    title: '晚上课程节数',
                                    value: config.eveningCount,
                                    min: 1,
                                    max: 30,
                                    warningText: eveningCardWarning,
                                    buttonColor: const Color(0xFFD37F95),
                                    onChanged: (int value) async {
                                      await updateConfig((config) {
                                        final _SegmentAnchors anchors = config.captureAnchors();
                                        config.setEveningCountPreferIncrease(value);
                                        config.rebuildSectionsByAnchors(anchors);
                                      });
                                      setModalState(() {
                                        eveningWarningText = null;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  buildSectionEditors(config.eveningStart, config.eveningEnd),
                                ],
                              ),
                            ),
                            _SidebarGroupCard(
                              title: '周数设置',
                              icon: Icons.repeat,
                              color: const Color(0xFFECE6FF),
                              expanded: _expandedSidebarGroup == 5,
                              onToggle: () => setModalState(() {
                                _expandedSidebarGroup = _expandedSidebarGroup == 5 ? -1 : 5;
                              }),
                              child: Column(
                                children: <Widget>[
                                  _StepInputRow(
                                    title: '学习周数',
                                    value: config.termWeeks,
                                    min: 1,
                                    max: 35,
                                    buttonColor: const Color(0xFFA58ADC),
                                    onChanged: (int value) async {
                                      await updateConfig((config) => config.termWeeks = value);
                                      setModalState(() {});
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '每周起始日',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTokens.textMain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 88,
                                    child: CupertinoPicker(
                                      looping: true,
                                      itemExtent: 30,
                                      selectionOverlay: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: const Color(0x20FFFFFF),
                                          border: Border.symmetric(
                                            horizontal: BorderSide(color: Color(0x44FFFFFF)),
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      scrollController: FixedExtentScrollController(
                                        initialItem: config.weekStartDay - 1,
                                      ),
                                      onSelectedItemChanged: (int index) async {
                                        await updateConfig((config) => config.weekStartDay = index + 1);
                                        setModalState(() {});
                                      },
                                      children: const <Widget>[
                                        Center(child: Text('星期一', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain))),
                                        Center(child: Text('星期二', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain))),
                                        Center(child: Text('星期三', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain))),
                                        Center(child: Text('星期四', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain))),
                                        Center(child: Text('星期五', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain))),
                                        Center(child: Text('星期六', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain))),
                                        Center(child: Text('星期日', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _SidebarGroupCard(
                              title: '开学日期',
                              icon: Icons.event,
                              color: const Color(0xFFE6F8FF),
                              expanded: _expandedSidebarGroup == 6,
                              onToggle: () => setModalState(() {
                                _expandedSidebarGroup = _expandedSidebarGroup == 6 ? -1 : 6;
                              }),
                              trailingText: DateFormat('yyyy-MM-dd').format(config.semesterStartDate),
                              child: SizedBox(
                                height: 96,
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: CupertinoPicker(
                                        itemExtent: 30,
                                        scrollController: FixedExtentScrollController(
                                          initialItem: config.semesterStartDate.year - 2020,
                                        ),
                                        onSelectedItemChanged: (int index) async {
                                          await updateConfig((config) {
                                            config.semesterStartDate = DateTime(
                                              2020 + index,
                                              config.semesterStartDate.month,
                                              config.semesterStartDate.day,
                                            );
                                          });
                                          setModalState(() {});
                                        },
                                        children: List<Widget>.generate(
                                          20,
                                          (int index) => Center(
                                            child: Text(
                                              '${2020 + index}',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: CupertinoPicker(
                                        itemExtent: 30,
                                        scrollController: FixedExtentScrollController(
                                          initialItem: config.semesterStartDate.month - 1,
                                        ),
                                        onSelectedItemChanged: (int index) async {
                                          await updateConfig((config) {
                                            config.semesterStartDate = DateTime(
                                              config.semesterStartDate.year,
                                              index + 1,
                                              config.semesterStartDate.day,
                                            );
                                          });
                                          setModalState(() {});
                                        },
                                        children: List<Widget>.generate(
                                          12,
                                          (int index) => Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: CupertinoPicker(
                                        itemExtent: 30,
                                        scrollController: FixedExtentScrollController(
                                          initialItem: config.semesterStartDate.day - 1,
                                        ),
                                        onSelectedItemChanged: (int index) async {
                                          await updateConfig((config) {
                                            config.semesterStartDate = DateTime(
                                              config.semesterStartDate.year,
                                              config.semesterStartDate.month,
                                              index + 1,
                                            );
                                          });
                                          setModalState(() {});
                                        },
                                        children: List<Widget>.generate(
                                          31,
                                          (int index) => Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTokens.textMain),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final CurvedAnimation curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(-0.22, 0),
          end: Offset.zero,
        ).animate(curve);
        final Animation<double> scale = Tween<double>(begin: 0.985, end: 1).animate(curve);
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(
              scale: scale,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
    );

    tableNameController.dispose();
  }

  Future<void> _switchCourseTable(int tableId, String tableName) async {
    // 切换课表只更新当前展示上下文，不修改数据库原始数据。
    final List<CourseEntity> courses = await _scheduleRepository.getCoursesByTableId(tableId);
    final List<CourseTableEntity> tables = await _scheduleRepository.getCourseTables();
    CourseTableEntity? target;
    for (final CourseTableEntity table in tables) {
      if (table.id == tableId) {
        target = table;
        break;
      }
    }
    final _ScheduleConfig config = _decodeConfig(target?.classTimeListJson);
    _tableConfigs[tableId] = config;
    _applyConfigToTimeline(config);
    _currentWeek = _computeCurrentWeek(config);
    _displayWeek = _currentWeek <= 0 ? 1 : _currentWeek;
    if (!mounted) {
      return;
    }
    setState(() {
      _activeTableId = tableId;
      _activeTableName = tableName;
      _courses = courses;
    });
    _scheduleRepository.setActiveTableId(tableId);
  }

  _ScheduleConfig _decodeConfig(String? rawJson) {
    return _ScheduleConfig.fromJson(rawJson);
  }

  _ScheduleConfig _activeConfig() {
    final int? tableId = _activeTableId;
    if (tableId == null) {
      return _ScheduleConfig.defaults();
    }
    return _tableConfigs[tableId] ?? _ScheduleConfig.defaults();
  }

  void _applyConfigToTimeline(_ScheduleConfig config) {
    _periodTimes
      ..clear()
      ..addAll(
        config.sections.map((section) => '${section.start}\n-${section.end}'),
      );
  }

  int _computeCurrentWeek(_ScheduleConfig config) {
    final DateTime today = DateTime.now();
    final DateTime start = DateTime(
      config.semesterStartDate.year,
      config.semesterStartDate.month,
      config.semesterStartDate.day,
    );
    final int deltaDays = today.difference(start).inDays;
    if (deltaDays < 0) {
      return 0;
    }
    final int week = deltaDays ~/ 7 + 1;
    if (week > config.termWeeks) {
      return config.termWeeks;
    }
    return week;
  }

  Future<void> _persistActiveConfig() async {
    final int? tableId = _activeTableId;
    if (tableId == null) {
      return;
    }
    final _ScheduleConfig config = _activeConfig();
    await _scheduleRepository.updateCourseTableConfig(
      tableId: tableId,
      classTimeListJson: config.toJson(),
      semesterStartMonday:
          '${config.semesterStartDate.year.toString().padLeft(4, '0')}-${config.semesterStartDate.month.toString().padLeft(2, '0')}-${config.semesterStartDate.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _handleCameraAdd() async {
    // 拍照链路只负责权限与采集入口，OCR 解析在后续能力中接入。
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? captured = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (!mounted) {
        return;
      }

      if (captured == null) {
        // 用户主动取消不属于异常，提示后直接返回。
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消拍照，未写入课程数据。')),
        );
        return;
      }

      await DuckModal.show<void>(
        context: context,
        child: DuckModalFrame(
          title: '拍照添加',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space12),
            child: Text('已获取照片：${captured.name}\nOCR识别与课程抽取将在后续任务接入。'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      // 统一拦截权限与设备能力异常，避免流程静默失败。
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法访问相机，请检查系统权限设置。')),
      );
    }
  }

  Future<void> _openCourseDetail(int period, List<CourseEntity> courses) async {
    if (courses.isEmpty) {
      await DuckModal.show<void>(
        context: context,
        child: DuckModalFrame(
          title: '第$period节课程详情',
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTokens.space12),
            child: Text('该节次暂无课程。'),
          ),
        ),
      );
      return;
    }

    final Map<String, List<TodoItem>> todoByCourseName = <String, List<TodoItem>>{};
    for (final CourseEntity course in courses) {
      if (todoByCourseName.containsKey(course.name)) {
        continue;
      }
      final List<TodoItem> linkedTodos = await _todoRepository.getTodosByCourseName(
        course.name,
        tableId: _activeTableId,
      );
      todoByCourseName[course.name] = linkedTodos;
    }

    if (!mounted) {
      return;
    }

    await DuckModal.show<void>(
      context: context,
      barrierDismissible: false,
      child: _CourseActivatedModal(
        courses: courses,
        todoByCourseName: todoByCourseName,
        maxPeriod: _periodTimes.length,
        onSave: (List<_CourseDraftUpdate> updates) async {
          for (final _CourseDraftUpdate update in updates) {
            await _scheduleRepository.updateCourseDetail(
              courseId: update.courseId,
              name: update.name,
              weekTime: update.weekday,
              weeksJson: update.weeksJson,
              startTime: update.sectionStart,
              timeCount: update.sectionEnd - update.sectionStart + 1,
              teacher: update.teacher,
              classroom: update.location,
            );

            await _todoRepository.renameCourseName(
              from: update.originalName,
              to: update.name,
              tableId: _activeTableId,
            );
          }
          await _loadScheduleData();
        },
        onDelete: (int index) async {
          final CourseEntity course = courses[index];
          final int? courseId = course.id;
          if (courseId == null) {
            return;
          }

          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '删除课程',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.textMain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '确认删除课程“${course.name}”吗？',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTokens.textMain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2F2A25),
                            ),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD24B5A),
                            ),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          if (confirmed != true) {
            return;
          }

          // 课程删除联动：彻底物理删除所有关联待办（含未完成/已完成）。
          final int removedTodos = await _todoRepository.deleteTodosByCourseName(
            course.name,
            tableId: _activeTableId,
          );
          await _scheduleRepository.deleteCourse(courseId);
          await _loadScheduleData();

          if (!mounted) {
            return;
          }
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除课程：${course.name}，联动删除待办 $removedTodos 条')),
          );
        },
      ),
    );
  }

  Widget _buildCourseDragLayer({
    required double colWidth,
    required double rowHeight,
  }) {
    final _CourseDragPayload? activeDrag = _activeCourseDrag;
    if (activeDrag == null) {
      return const SizedBox.shrink();
    }

    final int maxPeriod = _periodTimes.length;
    final _CourseDragHover? hover = _courseDragHover;
    final int span = activeDrag.timeCount.clamp(1, maxPeriod).toInt();
    final int highlightSpan = hover == null
        ? span
        : (math.min(maxPeriod, hover.periodStart + span - 1) - hover.periodStart + 1);

    return Positioned.fill(
      child: Stack(
        children: <Widget>[
          for (int period = 1; period <= maxPeriod; period++)
            for (int dayColumn = 1; dayColumn <= 7; dayColumn++)
              Positioned(
                left: (dayColumn - 1) * colWidth,
                top: (period - 1) * rowHeight,
                width: colWidth,
                height: rowHeight,
                child: DragTarget<_CourseDragPayload>(
                  onWillAcceptWithDetails: (DragTargetDetails<_CourseDragPayload> details) {
                    final _CourseDropDecision decision = _canDropCourseAt(
                      payload: details.data,
                      targetDayColumn: dayColumn,
                      targetStartPeriod: period,
                    );
                    if (!decision.accepted) {
                      _courseDragRejectMessage = decision.message;
                      return false;
                    }

                    _courseDragRejectMessage = null;
                    final _CourseDragHover next =
                        _CourseDragHover(dayColumn: dayColumn, periodStart: period);
                    if (_courseDragHover != next) {
                      setState(() {
                        _courseDragHover = next;
                      });
                    }
                    return true;
                  },
                  onMove: (DragTargetDetails<_CourseDragPayload> details) {
                    final _CourseDragHover next =
                        _CourseDragHover(dayColumn: dayColumn, periodStart: period);
                    if (_courseDragHover != next) {
                      setState(() {
                        _courseDragHover = next;
                      });
                    }
                  },
                  onLeave: (details) {
                    if (_courseDragHover ==
                        _CourseDragHover(dayColumn: dayColumn, periodStart: period)) {
                      setState(() {
                        _courseDragHover = null;
                      });
                    }
                  },
                  onAcceptWithDetails: (DragTargetDetails<_CourseDragPayload> details) {
                    _courseDragRejectMessage = null;
                    _applyCourseDragDrop(
                      payload: details.data,
                      targetDayColumn: dayColumn,
                      targetStartPeriod: period,
                    );
                  },
                  builder: (
                    BuildContext context,
                    List<_CourseDragPayload?> candidateData,
                    List<dynamic> rejectedData,
                  ) {
                    return const SizedBox.expand();
                  },
                ),
              ),
          if (hover != null)
            Positioned(
              left: (hover.dayColumn - 1) * colWidth + 1.5,
              top: (hover.periodStart - 1) * rowHeight + 1.5,
              width: colWidth - 3,
              height: rowHeight * highlightSpan - 3,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTokens.duckYellow, width: 1),
                    color: AppTokens.duckYellow.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleGrid() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double leftWidth = screenWidth < 380 ? 30 : 32;

    if (_loadingSchedule) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<_RenderedCourseBlock> blocks = _buildRenderedBlocks(_courses);
    final Set<String> occupiedCells = <String>{
      for (final _RenderedCourseBlock block in blocks)
        for (int period = block.start; period < block.start + block.span; period++)
          '${block.dayColumn}-$period',
    };

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 760;
        final double rowHeight =
          (availableHeight / _periodTimes.length).clamp(68.0, 92.0).toDouble();
        final double gridHeight = math.max(
          rowHeight * _periodTimes.length + 56,
          availableHeight,
        );

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            physics: _quickAddSelection == null && _activeCourseDrag == null
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: gridHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: leftWidth,
                    child: Column(
                      children: List<Widget>.generate(_periodTimes.length, (int index) {
                        final int period = index + 1;
                        return SizedBox(
                          height: rowHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                '$period',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF40352A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _periodTimes[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  height: 1.2,
                                  color: Color(0xFFB7AA95),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final double colWidth = constraints.maxWidth / 7;
                        _gridColWidth = colWidth;
                        _gridRowHeight = rowHeight;

                        final _QuickAddSelection? selection = _quickAddSelection;
                        final bool showSelection = selection != null;
                        final int selectionDayStart =
                          selection?.dayStart.clamp(1, 7).toInt() ?? 1;
                        final int selectionDayEnd =
                          selection?.dayEnd.clamp(1, 7).toInt() ?? 1;
                        final int selectionPeriodStart =
                          selection?.periodStart.clamp(1, _periodTimes.length).toInt() ?? 1;
                        final int selectionPeriodEnd =
                          selection?.periodEnd.clamp(1, _periodTimes.length).toInt() ?? 1;

                        final double selectionLeft = (selectionDayStart - 1) * colWidth;
                        final double selectionTop =
                            (selectionPeriodStart - 1) * rowHeight;
                        final double selectionWidth =
                            (selectionDayEnd - selectionDayStart + 1) * colWidth;
                        final double selectionHeight =
                            (selectionPeriodEnd - selectionPeriodStart + 1) * rowHeight;
                        final int selectionDayCount =
                            selectionDayEnd - selectionDayStart + 1;
                        final int selectionPeriodCount =
                            selectionPeriodEnd - selectionPeriodStart + 1;

                        return Stack(
                          key: _gridAreaKey,
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            for (int row = 0; row < _periodTimes.length; row++)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: row * rowHeight,
                                child: Container(
                                  height: rowHeight,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Color(0xFFF1E9DA), width: 0.8),
                                    ),
                                  ),
                                ),
                              ),
                            for (int period = 1; period <= _periodTimes.length; period++)
                              for (int dayColumn = 1; dayColumn <= 7; dayColumn++)
                                if (!occupiedCells.contains('$dayColumn-$period'))
                                  Positioned(
                                    left: (dayColumn - 1) * colWidth,
                                    top: (period - 1) * rowHeight,
                                    width: colWidth,
                                    height: rowHeight,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        _showQuickAddSelectionForCell(
                                          dayColumn: dayColumn,
                                          period: period,
                                        );
                                      },
                                    ),
                                  ),
                            for (final _RenderedCourseBlock block in blocks)
                              _buildCourseCard(
                                block: block,
                                colWidth: colWidth,
                                rowHeight: rowHeight,
                                color: _colorForCourse(block.course),
                              ),
                            if (_activeCourseDrag != null)
                              _buildCourseDragLayer(
                                colWidth: colWidth,
                                rowHeight: rowHeight,
                              ),
                            if (showSelection)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _clearQuickAddSelection,
                                ),
                              ),
                            if (showSelection)
                              Positioned(
                                left: selectionLeft,
                                top: selectionTop,
                                width: selectionWidth,
                                height: selectionHeight,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: <Widget>[
                                    Positioned.fill(
                                      child: Listener(
                                        onPointerMove: (PointerMoveEvent event) {
                                          final bool touchLike = event.kind == PointerDeviceKind.touch ||
                                              event.kind == PointerDeviceKind.stylus ||
                                              event.kind == PointerDeviceKind.invertedStylus;
                                          final bool mousePrimaryDown =
                                              (event.buttons & 0x01) != 0;
                                          if (!touchLike && !mousePrimaryDown) {
                                            return;
                                          }
                                          _updateQuickAddSelectionFromGlobal(event.position);
                                        },
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _openManualAddFromQuickSelection,
                                          onPanUpdate: (DragUpdateDetails details) {
                                            _updateQuickAddSelectionFromGlobal(details.globalPosition);
                                          },
                                          onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
                                            _updateQuickAddSelectionFromGlobal(details.globalPosition);
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Stack(
                                              children: <Widget>[
                                                for (int dayOffset = 0;
                                                    dayOffset < selectionDayCount;
                                                    dayOffset++)
                                                  for (int periodOffset = 0;
                                                      periodOffset < selectionPeriodCount;
                                                      periodOffset++)
                                                    Positioned(
                                                      left: dayOffset * colWidth,
                                                      top: periodOffset * rowHeight,
                                                      width: colWidth,
                                                      height: rowHeight,
                                                      child: Container(
                                                        color: AppTokens.duckYellow,
                                                      ),
                                                    ),
                                                Positioned.fill(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: Colors.white.withValues(alpha: 0.9),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const Center(
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: selectionLeft + selectionWidth + 38 > constraints.maxWidth
                                          ? -38
                                          : null,
                                      right: selectionLeft + selectionWidth + 38 > constraints.maxWidth
                                          ? null
                                          : -38,
                                      top: math.max(
                                        4,
                                        (selectionHeight - 52) / 2,
                                      ),
                                      child: IgnorePointer(
                                        child: Container(
                                          width: 30,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.70),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(
                                                Icons.keyboard_arrow_up_rounded,
                                                size: 18,
                                                color: AppTokens.textMuted,
                                              ),
                                              SizedBox(height: 2),
                                              Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                size: 18,
                                                color: AppTokens.textMuted,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: math.max(
                                        2,
                                        (selectionWidth - 52) / 2,
                                      ),
                                      top: selectionTop > 36 ? -34 : null,
                                      bottom: selectionTop > 36 ? null : -34,
                                      child: IgnorePointer(
                                        child: Container(
                                          width: 52,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.70),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Icon(
                                                Icons.keyboard_arrow_left_rounded,
                                                size: 18,
                                                color: AppTokens.textMuted,
                                              ),
                                              SizedBox(width: 2),
                                              Icon(
                                                Icons.keyboard_arrow_right_rounded,
                                                size: 18,
                                                color: AppTokens.textMuted,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseCard({
    required _RenderedCourseBlock block,
    required double colWidth,
    required double rowHeight,
    required Color color,
  }) {
    final CourseEntity course = block.course;
    final int dayColumn = block.dayColumn.clamp(1, 7);
    final int start = block.start.clamp(1, _periodTimes.length);
    final int span = block.span.clamp(1, 4);
    final Color activeColor = _normalizeCourseDisplayColor(color);
    final Color finalColor = block.active ? activeColor : const Color(0xFFE1DED7);
    const Color titleColor = Color(0xFF1F1A14);
    const Color metaColor = Color(0xFF1F1A14);

    final int dragTimeCount = course.timeCount.clamp(1, _periodTimes.length).toInt();
    final _CourseDragPayload dragPayload = _CourseDragPayload(
      course: course,
      courseId: course.id,
      sourceDayColumn: dayColumn,
      sourceStart: start,
      timeCount: dragTimeCount,
      weeks: _parseWeeks(course.weeksJson),
    );

    Widget buildCardVisual({
      required double scale,
      required double opacity,
      required bool withShadow,
    }) {
      return Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
            decoration: BoxDecoration(
              color: finalColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: withShadow
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 24),
                      child: Text(
                        course.name,
                        textAlign: TextAlign.center,
                        maxLines: span >= 2 ? 3 : 2,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        course.teacher?.isNotEmpty == true ? course.teacher! : '未填教师',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.15,
                          color: metaColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        course.classroom?.isNotEmpty == true ? course.classroom! : '未填地点',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.15,
                          color: metaColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Widget tapCard = GestureDetector(
      onTap: () {
        final List<CourseEntity> detailCourses = _collectDetailCourses(block);
        _openCourseDetail(
          start,
          detailCourses.isEmpty ? block.detailCourses : detailCourses,
        );
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.96, end: 1),
        builder: (BuildContext context, double value, Widget? child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: value, child: child),
          );
        },
        child: buildCardVisual(
          scale: 1,
          opacity: 1,
          withShadow: false,
        ),
      ),
    );

    return Positioned(
      left: (dayColumn - 1) * colWidth + 2,
      top: (start - 1) * rowHeight + 3,
      width: colWidth - 4,
      height: rowHeight * span - 6,
      child: LongPressDraggable<_CourseDragPayload>(
        data: dragPayload,
        delay: const Duration(milliseconds: 300),
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: colWidth - 4,
            height: rowHeight * span - 6,
            child: buildCardVisual(
              scale: 0.95,
              opacity: 0.9,
              withShadow: true,
            ),
          ),
        ),
        childWhenDragging: Container(
          decoration: BoxDecoration(
            color: AppTokens.duckYellow.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onDragStarted: () {
          _startCourseDrag(dragPayload);
        },
        onDragUpdate: (DragUpdateDetails details) {
          if (_isPointInsideGrid(details.globalPosition)) {
            return;
          }
          if (_courseDragHover == null && _courseDragRejectMessage == null) {
            return;
          }
          setState(() {
            _courseDragHover = null;
            _courseDragRejectMessage = null;
          });
        },
        onDragCompleted: _clearCourseDragState,
        onDraggableCanceled: (Velocity velocity, Offset offset) {
          final String? rejectMessage = _courseDragRejectMessage;
          _clearCourseDragState();
          if (rejectMessage != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(rejectMessage)),
            );
          }
        },
        onDragEnd: (DraggableDetails details) {
          if (_activeCourseDrag != null) {
            _clearCourseDragState();
          }
        },
        child: tapCard,
      ),
    );
  }

  List<_RenderedCourseBlock> _buildRenderedBlocks(List<CourseEntity> source) {
    final List<_RenderedCourseBlock> result = <_RenderedCourseBlock>[];
    final _ScheduleConfig config = _activeConfig();
    final bool showInactiveOnGrid = _currentWeek <= 0 || _isSemesterEnded(config);

    for (int dayColumn = 1; dayColumn <= 7; dayColumn++) {
      final int weekday = _weekdayForColumn(dayColumn, config.weekStartDay);
      final List<_ResolvedSlot> slots = List<_ResolvedSlot>.generate(
        _periodTimes.length + 1,
        (int _) => const _ResolvedSlot.empty(),
      );

      for (int period = 1; period <= _periodTimes.length; period++) {
        final List<CourseEntity> active = source
            .where((CourseEntity c) =>
            c.weekTime == weekday && _coversPeriod(c, period) && _isCourseInDisplayedWeek(c))
            .toList(growable: false)
          ..sort((CourseEntity a, CourseEntity b) => a.name.compareTo(b.name));

        if (active.isNotEmpty) {
          slots[period] = _ResolvedSlot(primary: active.first, all: active, active: true);
          continue;
        }

        final List<CourseEntity> inactive = source
            .where((CourseEntity c) =>
            c.weekTime == weekday && _coversPeriod(c, period) && !_isCourseInDisplayedWeek(c))
            .toList(growable: false)
          ..sort((CourseEntity a, CourseEntity b) => a.name.compareTo(b.name));

        if (showInactiveOnGrid && inactive.isNotEmpty) {
          slots[period] = _ResolvedSlot(primary: inactive.first, all: inactive, active: false);
        }
      }

      int period = 1;
      while (period <= _periodTimes.length) {
        final _ResolvedSlot current = slots[period];
        if (current.primary == null) {
          period++;
          continue;
        }

        int end = period;
        while (end + 1 <= _periodTimes.length) {
          final _ResolvedSlot next = slots[end + 1];
          if (next.primary == null) {
            break;
          }
          if (next.active != current.active) {
            break;
          }
          if (next.primary!.name != current.primary!.name) {
            break;
          }
          if (next.primary!.weekTime != current.primary!.weekTime) {
            break;
          }
          end++;
        }

        result.add(
          _RenderedCourseBlock(
            course: current.primary!,
            dayColumn: dayColumn,
            start: period,
            span: end - period + 1,
            active: current.active,
            detailCourses: current.all,
          ),
        );
        period = end + 1;
      }
    }

    return result;
  }

  bool _coversPeriod(CourseEntity course, int period) {
    final int start = course.startTime;
    final int end = course.startTime + course.timeCount - 1;
    return period >= start && period <= end;
  }

  List<CourseEntity> _collectDetailCourses(_RenderedCourseBlock block) {
    final int day = block.course.weekTime;
    final int rangeStart = block.start;
    final int rangeEnd = block.start + block.span - 1;

    final List<CourseEntity> matched = _courses.where((CourseEntity course) {
      if (course.weekTime != day) {
        return false;
      }
      final int start = course.startTime;
      final int end = course.startTime + course.timeCount - 1;
      return !(end < rangeStart || start > rangeEnd);
    }).toList(growable: false);

    matched.sort((CourseEntity a, CourseEntity b) {
      final bool aActive = _isCourseInDisplayedWeek(a);
      final bool bActive = _isCourseInDisplayedWeek(b);
      if (aActive != bActive) {
        return aActive ? -1 : 1;
      }
      final int byStart = a.startTime.compareTo(b.startTime);
      if (byStart != 0) {
        return byStart;
      }
      return a.name.compareTo(b.name);
    });
    return matched;
  }

  bool _isCourseInDisplayedWeek(CourseEntity course) {
    if (_isSemesterEnded(_activeConfig())) {
      return false;
    }
    final List<int> weeks = _parseWeeks(course.weeksJson);
    if (weeks.isEmpty) {
      return true;
    }
    final int displayWeek = _effectiveDisplayWeek(_activeConfig());
    return weeks.contains(displayWeek);
  }

  List<int> _parseWeeks(String weeksJson) {
    try {
      final List<dynamic> raw = jsonDecode(weeksJson) as List<dynamic>;
      return raw
          .whereType<num>()
          .map((num item) => item.toInt())
          .where((int value) => value > 0)
          .toList(growable: false);
    } catch (_) {
      return <int>[];
    }
  }

  // ignore: unused_element
  Map<String, Color> _buildAdjacentAwareColorMap(List<CourseEntity> courses) {
    const List<Color> palette = <Color>[
      Color(0xFFD45E6A),
      Color(0xFFCBA42F),
      Color(0xFF4A88D2),
      Color(0xFFB6C223),
      Color(0xFF896ED8),
      Color(0xFF2AA4A2),
      Color(0xFFD68152),
      Color(0xFFA19586),
    ];

    final List<String> names = courses
        .map((CourseEntity item) => item.name)
        .toSet()
        .toList(growable: false)
      ..sort();

    final Map<String, Set<String>> neighbors = <String, Set<String>>{};
    for (final String name in names) {
      neighbors[name] = <String>{};
    }

    for (int i = 0; i < courses.length; i++) {
      for (int j = i + 1; j < courses.length; j++) {
        final CourseEntity a = courses[i];
        final CourseEntity b = courses[j];
        if (a.name == b.name) {
          continue;
        }
        if (_isAdjacentCourse(a, b)) {
          neighbors[a.name]!.add(b.name);
          neighbors[b.name]!.add(a.name);
        }
      }
    }

    final Map<String, Color> picked = <String, Color>{};

    for (final String currentName in names) {
      final Set<int> blocked = <int>{};
      for (final String neighborName in neighbors[currentName]!) {
        final Color? used = picked[neighborName];
        if (used == null) {
          continue;
        }
        blocked.add(palette.indexOf(used));
      }

      final int preferred = _stableColorIndex(currentName, palette.length);
      int selected = preferred;
      if (blocked.contains(selected)) {
        for (int i = 0; i < palette.length; i++) {
          final int candidate = (preferred + i) % palette.length;
          if (!blocked.contains(candidate)) {
            selected = candidate;
            break;
          }
        }
      }
      picked[currentName] = palette[selected];
    }

    return picked;
  }

  bool _isAdjacentCourse(CourseEntity a, CourseEntity b) {
    final int aStart = a.startTime;
    final int aEnd = a.startTime + a.timeCount - 1;
    final int bStart = b.startTime;
    final int bEnd = b.startTime + b.timeCount - 1;

    if (a.weekTime == b.weekTime) {
      final bool overlapOrTouch = !(aEnd + 1 < bStart || bEnd + 1 < aStart);
      return overlapOrTouch;
    }
    if ((a.weekTime - b.weekTime).abs() == 1) {
      return !(aEnd < bStart || bEnd < aStart);
    }
    return false;
  }

  int _stableColorIndex(String seed, int paletteLength) {
    final int hash = seed.runes.fold<int>(0, (int v, int e) => v * 31 + e);
    return hash.abs() % paletteLength;
  }

  List<DateTime> _currentWeekDates(DateTime now, int weekStartDay) {
    final int startDay = weekStartDay.clamp(1, 7);
    final int delta = (now.weekday - startDay + 7) % 7;
    final DateTime start = now.subtract(Duration(days: delta));
    return List<DateTime>.generate(7, (int index) => start.add(Duration(days: index)));
  }

  int _effectiveDisplayWeek(_ScheduleConfig config) {
    final int minWeek = 1;
    final int maxWeek = config.termWeeks.clamp(1, 60).toInt();
    return _displayWeek.clamp(minWeek, maxWeek).toInt();
  }

  int _weekdayForColumn(int dayColumn, int weekStartDay) {
    final int base = weekStartDay.clamp(1, 7);
    return ((base - 1 + (dayColumn - 1)) % 7) + 1;
  }

  bool _isSemesterEnded(_ScheduleConfig config) {
    final DateTime today = DateTime.now();
    final DateTime start = DateTime(
      config.semesterStartDate.year,
      config.semesterStartDate.month,
      config.semesterStartDate.day,
    );
    final int deltaDays = today.difference(start).inDays;
    if (deltaDays < 0) {
      return false;
    }
    final int week = deltaDays ~/ 7 + 1;
    return week > config.termWeeks;
  }

  void _shiftDisplayWeek(int delta) {
    final _ScheduleConfig config = _activeConfig();
    final int minWeek = 1;
    final int maxWeek = config.termWeeks.clamp(1, 60).toInt();
    final int next = (_effectiveDisplayWeek(config) + delta).clamp(minWeek, maxWeek).toInt();
    if (next == _displayWeek) {
      return;
    }
    setState(() {
      _displayWeek = next;
    });
  }

  void _resetDisplayWeekToCurrent() {
    if (_currentWeek <= 0 || _displayWeek == _currentWeek) {
      return;
    }
    setState(() {
      _displayWeek = _currentWeek;
    });
  }

  List<DateTime> _weekDatesForDisplay(_ScheduleConfig config, int displayWeek) {
    if (displayWeek <= 0) {
      return _currentWeekDates(DateTime.now(), config.weekStartDay);
    }

    final DateTime seed = config.semesterStartDate.add(Duration(days: (displayWeek - 1) * 7));
    final int startDay = config.weekStartDay.clamp(1, 7);
    final int delta = (seed.weekday - startDay + 7) % 7;
    final DateTime start = seed.subtract(Duration(days: delta));
    return List<DateTime>.generate(7, (int index) => start.add(Duration(days: index)));
  }

  String _weekDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '星期一';
      case DateTime.tuesday:
        return '星期二';
      case DateTime.wednesday:
        return '星期三';
      case DateTime.thursday:
        return '星期四';
      case DateTime.friday:
        return '星期五';
      case DateTime.saturday:
        return '星期六';
      default:
        return '星期日';
    }
  }

  String _buildStatusLine() {
    if (_loadingConfig || _loadingSchedule) {
      return '数据加载中...';
    }
    if (_configError != null) {
      return '学校配置加载失败：$_configError';
    }
    if (_scheduleError != null) {
      return '课表加载失败：$_scheduleError';
    }
    return '当前课表：$_activeTableName | 学校配置 $_schoolConfigCount 所';
  }

  Color _colorForCourse(CourseEntity course) {
    final String? colorHex = course.colorHex?.trim();
    if (colorHex != null && colorHex.isNotEmpty) {
      final String normalized = colorHex.startsWith('#') ? colorHex.substring(1) : colorHex;
      if (normalized.length == 6) {
        final int? value = int.tryParse('FF$normalized', radix: 16);
        if (value != null) {
          return _normalizeCourseDisplayColor(Color(value));
        }
      }
    }
    return _colorForCourseName(course.name);
  }

  Color _colorForCourseName(String name) {
    const List<Color> palette = <Color>[
      Color(0xFFD45E6A),
      Color(0xFFCBA42F),
      Color(0xFF4A88D2),
      Color(0xFFB6C223),
      Color(0xFF896ED8),
      Color(0xFF2AA4A2),
      Color(0xFFD68152),
      Color(0xFFA19586),
    ];
    final int hash = name.runes.fold<int>(0, (int v, int e) => v * 31 + e);
    final int index = hash.abs() % palette.length;
    return palette[index];
  }

  Color _normalizeCourseDisplayColor(Color source) {
    const List<Color> oldPalette = <Color>[
      Color(0xFFEAA4AF),
      Color(0xFFF2C27D),
      Color(0xFFA9CDFE),
      Color(0xFF9ED9A2),
      Color(0xFFC7C1F8),
      Color(0xFF8FD8D0),
      Color(0xFFF5B57A),
      Color(0xFFD9C1A5),
    ];
    const List<Color> newPalette = <Color>[
      Color(0xFFD45E6A),
      Color(0xFFCBA42F),
      Color(0xFF4A88D2),
      Color(0xFFB6C223),
      Color(0xFF896ED8),
      Color(0xFF2AA4A2),
      Color(0xFFD68152),
      Color(0xFFA19586),
    ];

    for (int i = 0; i < oldPalette.length; i++) {
      if (source.toARGB32() == oldPalette[i].toARGB32()) {
        return newPalette[i];
      }
    }

    if (source.computeLuminance() > 0.58) {
      return Color.alphaBlend(const Color(0x66000000), source);
    }
    return source;
  }

  int _toMinute(String hhmm) {
    final List<String> parts = hhmm.split(':');
    final int h = int.tryParse(parts.first) ?? 0;
    final int m = int.tryParse(parts.last) ?? 0;
    return h * 60 + m;
  }

  String _formatMinute(int minute) {
    final int h = ((minute ~/ 60) % 24 + 24) % 24;
    final int m = ((minute % 60) + 60) % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<String?> _openTimeEditDialog(
    BuildContext context,
    String initialValue, {
    String? Function(String value)? validator,
  }) async {
    final List<String> parts = initialValue.split(':');
    int hour = int.tryParse(parts.first) ?? 8;
    int minute = int.tryParse(parts.last) ?? 0;

    final TextEditingController hourController = TextEditingController(
      text: hour.toString().padLeft(2, '0'),
    );
    final TextEditingController minuteController = TextEditingController(
      text: minute.toString().padLeft(2, '0'),
    );
    final FixedExtentScrollController hourWheelController =
      FixedExtentScrollController(initialItem: hour);
    final FixedExtentScrollController minuteWheelController =
      FixedExtentScrollController(initialItem: minute);

    bool wheelMode = false;
    String? errorText;

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void syncTextFromWheel() {
              hourController.text = hour.toString().padLeft(2, '0');
              minuteController.text = minute.toString().padLeft(2, '0');
            }

            bool applyManualInput() {
              final int? nextHour = int.tryParse(hourController.text.trim());
              final int? nextMinute = int.tryParse(minuteController.text.trim());
              if (nextHour == null || nextMinute == null) {
                setModalState(() {
                  errorText = '请输入有效数字';
                });
                return false;
              }
              if (nextHour < 0 || nextHour > 23 || nextMinute < 0 || nextMinute > 59) {
                setModalState(() {
                  errorText = '小时范围 0-23，分钟范围 0-59';
                });
                return false;
              }
              hour = nextHour;
              minute = nextMinute;
              setModalState(() {
                errorText = null;
                syncTextFromWheel();
              });
              return true;
            }

            final ThemeData themed = Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: AppTokens.duckYellow,
                selectionColor: AppTokens.duckYellow.withValues(alpha: 0.28),
                selectionHandleColor: AppTokens.duckYellow,
              ),
            );

            return Theme(
              data: themed,
              child: Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SizedBox(
                  width: 320,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '时间设置',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.textMain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    if (!wheelMode)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: hourController,
                              keyboardType: TextInputType.number,
                              cursorColor: AppTokens.duckYellow,
                              decoration: const InputDecoration(
                                labelText: '小时',
                                hintText: '00-23',
                                floatingLabelStyle: TextStyle(color: AppTokens.duckYellow),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTokens.duckYellow),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTokens.duckYellow, width: 2),
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(':', style: TextStyle(fontSize: 18)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: minuteController,
                              keyboardType: TextInputType.number,
                              cursorColor: AppTokens.duckYellow,
                              decoration: const InputDecoration(
                                labelText: '分钟',
                                hintText: '00-59',
                                floatingLabelStyle: TextStyle(color: AppTokens.duckYellow),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTokens.duckYellow),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTokens.duckYellow, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        height: 150,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 34,
                                scrollController: hourWheelController,
                                onSelectedItemChanged: (int value) {
                                  setModalState(() {
                                    hour = value;
                                    errorText = null;
                                    syncTextFromWheel();
                                  });
                                },
                                children: List<Widget>.generate(
                                  24,
                                  (int index) => Center(
                                    child: Text(index.toString().padLeft(2, '0')),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(':', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 34,
                                scrollController: minuteWheelController,
                                onSelectedItemChanged: (int value) {
                                  setModalState(() {
                                    minute = value;
                                    errorText = null;
                                    syncTextFromWheel();
                                  });
                                },
                                children: List<Widget>.generate(
                                  60,
                                  (int index) => Center(
                                    child: Text(index.toString().padLeft(2, '0')),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Text(
                          wheelMode ? '当前：滚轮模式' : '当前：手动输入模式',
                          style: const TextStyle(fontSize: 12, color: AppTokens.textMuted),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: wheelMode ? '切回手动输入' : '切换滚轮',
                          onPressed: () {
                            if (!wheelMode && !applyManualInput()) {
                              return;
                            }
                            setModalState(() {
                              wheelMode = !wheelMode;
                              errorText = null;
                              if (wheelMode) {
                                hourWheelController.jumpToItem(hour);
                                minuteWheelController.jumpToItem(minute);
                              }
                            });
                          },
                          icon: Icon(
                            wheelMode ? Icons.keyboard : Icons.tune,
                            size: 18,
                            color: AppTokens.duckYellow,
                          ),
                        ),
                      ],
                    ),
                    if (errorText != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2F2A25),
                            ),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: () {
                              if (!wheelMode && !applyManualInput()) {
                                return;
                              }
                              final String picked =
                                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                              final String? validationError = validator?.call(picked);
                              if (validationError != null) {
                                setModalState(() {
                                  errorText = validationError;
                                });
                                return;
                              }
                              Navigator.of(dialogContext).pop(
                                picked,
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTokens.duckYellow,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    return result;
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekDates,
    required this.weekStartDay,
    required this.cornerLabel,
    required this.leftSpacing,
  });

  final List<DateTime> weekDates;
  final int weekStartDay;
  final String cornerLabel;
  final double leftSpacing;

  static const List<String> _names = <String>[
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> orderedNames = <String>[
      ..._names.sublist(weekStartDay - 1),
      ..._names.sublist(0, weekStartDay - 1),
    ];
    return Row(
      children: <Widget>[
        SizedBox(
          width: leftSpacing,
          child: Text(
            cornerLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFAAA192),
            ),
          ),
        ),
        for (int i = 0; i < 7; i++)
          Expanded(
            child: Column(
              children: <Widget>[
                Text(
                  orderedNames[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: _isToday(weekDates[i])
                        ? const Color(0xFFD19B00)
                        : const Color(0xFFAAA192),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${weekDates[i].day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isToday(weekDates[i])
                        ? const Color(0xFFD19B00)
                        : const Color(0xFF5B4D3D),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _isToday(DateTime value) {
    final DateTime now = DateTime.now();
    return now.year == value.year && now.month == value.month && now.day == value.day;
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radius20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0C9),
          borderRadius: BorderRadius.circular(AppTokens.radius20),
        ),
        child: Icon(icon, color: AppTokens.textMain, size: 20),
      ),
    );
  }
}

class _RoundAddButton extends StatelessWidget {
  const _RoundAddButton({
    required this.onTap,
    required this.child,
    this.backgroundColor = AppTokens.duckYellow,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _CourseActivatedModal extends StatefulWidget {
  const _CourseActivatedModal({
    required this.courses,
    required this.todoByCourseName,
    required this.maxPeriod,
    required this.onSave,
    required this.onDelete,
  });

  final List<CourseEntity> courses;
  final Map<String, List<TodoItem>> todoByCourseName;
  final int maxPeriod;
  final Future<void> Function(List<_CourseDraftUpdate> updates) onSave;
  final Future<void> Function(int index) onDelete;

  @override
  State<_CourseActivatedModal> createState() => _CourseActivatedModalState();
}

class _CourseActivatedModalState extends State<_CourseActivatedModal> {
  int _index = 0;
  bool _saving = false;
  late final List<_CourseEditDraft> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = widget.courses
      .map(_CourseEditDraft.fromCourse)
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final _CourseEditDraft draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _showPreviousCourse() {
    if (_index <= 0) {
      return;
    }
    setState(() {
      _index -= 1;
    });
  }

  void _showNextCourse() {
    if (_index >= widget.courses.length - 1) {
      return;
    }
    setState(() {
      _index += 1;
    });
  }

  Future<void> _closeWithSave() async {
    if (_saving) {
      return;
    }
    FocusScope.of(context).unfocus();

    final String? validationError = _validateAllDrafts();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final List<_CourseDraftUpdate> updates = _collectUpdates();
    if (updates.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _saving = true;
    });
    try {
      await widget.onSave(updates);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('课程修改已保存。')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String? _validateAllDrafts() {
    for (int i = 0; i < _drafts.length; i++) {
      final _CourseEditDraft draft = _drafts[i];
      final String name = draft.nameController.text.trim();
      final int? weekStart = int.tryParse(draft.weekStartController.text.trim());
      final int? weekEnd = int.tryParse(draft.weekEndController.text.trim());
      final int? sectionStart = int.tryParse(draft.sectionStartController.text.trim());
      final int? sectionEnd = int.tryParse(draft.sectionEndController.text.trim());
      if (name.isEmpty) {
        return '第${i + 1}门课程名称不能为空。';
      }
      if (draft.weekday < 1 || draft.weekday > 7) {
        return '第${i + 1}门课程的星期不合法。';
      }
      if (weekStart == null || weekEnd == null) {
        return '第${i + 1}门课程周次必须是数字。';
      }
      if (weekStart < 1 || weekEnd < weekStart || weekEnd > 30) {
        return '第${i + 1}门课程周次范围应在1-30且起止合法。';
      }
      if (sectionStart == null || sectionEnd == null) {
        return '第${i + 1}门课程节次必须是数字。';
      }
      if (sectionStart < 1 ||
          sectionEnd < sectionStart ||
          sectionEnd > widget.maxPeriod) {
        return '第${i + 1}门课程节次范围应在1-${widget.maxPeriod}且起止合法。';
      }
    }
    return null;
  }

  List<_CourseDraftUpdate> _collectUpdates() {
    final List<_CourseDraftUpdate> updates = <_CourseDraftUpdate>[];
    for (int i = 0; i < _drafts.length; i++) {
      final _CourseDraftUpdate? update = _drafts[i].toUpdate(widget.courses[i]);
      if (update != null) {
        updates.add(update);
      }
    }
    return updates;
  }

  static String _formatTodoDeadline(String iso) {
    try {
      final DateTime deadline = DateTime.parse(iso).toLocal();
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime target = DateTime(deadline.year, deadline.month, deadline.day);
      final int dayDiff = target.difference(today).inDays;
      if (dayDiff == 1) {
        return '明天';
      }
      if (dayDiff == 2) {
        return '后天';
      }
      return DateFormat('MM-dd').format(deadline);
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<CourseEntity> courses = widget.courses;
    final CourseEntity course = courses[_index];
    final _CourseEditDraft draft = _drafts[_index];
    final List<TodoItem> linkedTodos =
        widget.todoByCourseName[course.name] ?? const <TodoItem>[];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: _closeWithSave,
              child: const SizedBox.expand(),
            ),
          ),
          Center(
            child: GestureDetector(
              onHorizontalDragEnd: (DragEndDetails details) {
                final double velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 160) {
                  return;
                }
                if (velocity > 0) {
                  _showPreviousCourse();
                } else {
                  _showNextCourse();
                }
              },
              child: Container(
                width: 340,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEDEDED)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
            Row(
              children: <Widget>[
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _closeWithSave,
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(Icons.close, size: 18, color: Color(0xFF4A4A4A)),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: draft.nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.textMain,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '课程名称',
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _saving ? null : () => widget.onDelete(_index),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(Icons.delete_outline, size: 18, color: Color(0xFFE16C7B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CourseEditableLine(
              label: '星期',
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: draft.weekday,
                  alignment: Alignment.center,
                  items: const <DropdownMenuItem<int>>[
                    DropdownMenuItem<int>(value: 1, child: Center(child: Text('一'))),
                    DropdownMenuItem<int>(value: 2, child: Center(child: Text('二'))),
                    DropdownMenuItem<int>(value: 3, child: Center(child: Text('三'))),
                    DropdownMenuItem<int>(value: 4, child: Center(child: Text('四'))),
                    DropdownMenuItem<int>(value: 5, child: Center(child: Text('五'))),
                    DropdownMenuItem<int>(value: 6, child: Center(child: Text('六'))),
                    DropdownMenuItem<int>(value: 7, child: Center(child: Text('日'))),
                  ],
                  onChanged: _saving
                      ? null
                      : (int? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            draft.weekday = value;
                          });
                        },
                ),
              ),
            ),
            _CourseEditableLine(
              label: '周次',
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: draft.weekStartController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('-', style: TextStyle(color: AppTokens.textMuted)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: draft.weekEndController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '周',
                    style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
                  ),
                ],
              ),
            ),
            _CourseEditableLine(
              label: '节次',
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: draft.sectionStartController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('-', style: TextStyle(color: AppTokens.textMuted)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: draft.sectionEndController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '节',
                    style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
                  ),
                ],
              ),
            ),
            _CourseEditableLine(
              label: '教师',
              child: TextFormField(
                controller: draft.teacherController,
                maxLength: 20,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  hintText: '请输入授课教师',
                ),
              ),
            ),
            _CourseEditableLine(
              label: '地点',
              child: TextFormField(
                controller: draft.locationController,
                maxLength: 30,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  hintText: '请输入上课地点',
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '待办',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.textMain,
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (linkedTodos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '暂无关联待办',
                  style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 138),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: linkedTodos.length > 3
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: linkedTodos.length,
                  itemBuilder: (BuildContext context, int index) {
                    final TodoItem item = linkedTodos[index];
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9E9E9)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTokens.textMain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTodoDeadline(item.dueAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: _index > 0 ? _showPreviousCourse : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_left,
                          size: 22,
                          color: _index > 0
                              ? const Color(0xFF2F2A25)
                              : const Color(0xFFC7C7C7),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${_index + 1} / ${courses.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppTokens.textMuted),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _index < courses.length - 1 ? _showNextCourse : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_right,
                          size: 22,
                          color: _index < courses.length - 1
                              ? const Color(0xFF2F2A25)
                              : const Color(0xFFC7C7C7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              '左右滑动或点击两侧箭头切换课程',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppTokens.textMuted),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  '保存中...',
                  style: TextStyle(fontSize: 10, color: AppTokens.textMuted),
                ),
              ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseEditableLine extends StatelessWidget {
  const _CourseEditableLine({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTokens.textMuted),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseDraftUpdate {
  const _CourseDraftUpdate({
    required this.courseId,
    required this.originalName,
    required this.name,
    required this.weekday,
    required this.weeksJson,
    required this.sectionStart,
    required this.sectionEnd,
    required this.teacher,
    required this.location,
  });

  final int courseId;
  final String originalName;
  final String name;
  final int weekday;
  final String weeksJson;
  final int sectionStart;
  final int sectionEnd;
  final String? teacher;
  final String? location;
}

class _CourseEditDraft {
  _CourseEditDraft({
    required this.nameController,
    required this.weekday,
    required this.weekStartController,
    required this.weekEndController,
    required this.sectionStartController,
    required this.sectionEndController,
    required this.teacherController,
    required this.locationController,
  });

  factory _CourseEditDraft.fromCourse(CourseEntity course) {
    final List<int> weeks = _decodeWeeks(course.weeksJson);
    final int weekStart = weeks.isEmpty ? 1 : weeks.first;
    final int weekEnd = weeks.isEmpty ? 16 : weeks.last;
    final int sectionStart = course.startTime;
    final int sectionEnd = course.startTime + course.timeCount - 1;
    return _CourseEditDraft(
      nameController: TextEditingController(text: course.name),
      weekday: course.weekTime <= 0 ? 1 : course.weekTime,
      weekStartController: TextEditingController(text: weekStart.toString()),
      weekEndController: TextEditingController(text: weekEnd.toString()),
      sectionStartController: TextEditingController(text: sectionStart.toString()),
      sectionEndController: TextEditingController(text: sectionEnd.toString()),
      teacherController: TextEditingController(text: course.teacher ?? ''),
      locationController: TextEditingController(text: course.classroom ?? ''),
    );
  }

  final TextEditingController nameController;
  int weekday;
  final TextEditingController weekStartController;
  final TextEditingController weekEndController;
  final TextEditingController sectionStartController;
  final TextEditingController sectionEndController;
  final TextEditingController teacherController;
  final TextEditingController locationController;

  _CourseDraftUpdate? toUpdate(CourseEntity original) {
    final int? courseId = original.id;
    if (courseId == null) {
      return null;
    }

    final String name = nameController.text.trim();
    final int weekStart = int.tryParse(weekStartController.text.trim()) ?? 1;
    final int weekEnd = int.tryParse(weekEndController.text.trim()) ?? weekStart;
    final int sectionStart = int.tryParse(sectionStartController.text.trim()) ?? 1;
    final int sectionEnd = int.tryParse(sectionEndController.text.trim()) ?? sectionStart;
    final String teacher = teacherController.text.trim();
    final String location = locationController.text.trim();
    final String weeksJson = jsonEncode(
      List<int>.generate(weekEnd - weekStart + 1, (int i) => weekStart + i),
    );

    final String originalTeacher = (original.teacher ?? '').trim();
    final String originalLocation = (original.classroom ?? '').trim();
    final int originalEnd = original.startTime + original.timeCount - 1;

    final bool changed = name != original.name ||
        weekday != original.weekTime ||
        weeksJson != original.weeksJson ||
        sectionStart != original.startTime ||
        sectionEnd != originalEnd ||
        teacher != originalTeacher ||
        location != originalLocation;
    if (!changed) {
      return null;
    }

    return _CourseDraftUpdate(
      courseId: courseId,
      originalName: original.name,
      name: name,
      weekday: weekday,
      weeksJson: weeksJson,
      sectionStart: sectionStart,
      sectionEnd: sectionEnd,
      teacher: teacher.isEmpty ? null : teacher,
      location: location.isEmpty ? null : location,
    );
  }

  void dispose() {
    nameController.dispose();
    weekStartController.dispose();
    weekEndController.dispose();
    sectionStartController.dispose();
    sectionEndController.dispose();
    teacherController.dispose();
    locationController.dispose();
  }

  static List<int> _decodeWeeks(String weeksJson) {
    try {
      final List<dynamic> raw = jsonDecode(weeksJson) as List<dynamic>;
      final List<int> weeks = raw
          .whereType<num>()
          .map((num item) => item.toInt())
          .where((int value) => value > 0)
          .toList(growable: false)
        ..sort();
      return weeks;
    } catch (_) {
      return const <int>[];
    }
  }
}

class _SidebarGroupCard extends StatelessWidget {
  const _SidebarGroupCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.trailingText,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 16, color: const Color(0xFF5F554A)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.textMain,
                    ),
                  ),
                  const Spacer(),
                  if (trailingText != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        trailingText!,
                        style: const TextStyle(fontSize: 11, color: AppTokens.textMuted),
                      ),
                    ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: const Color(0xFF776C60),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _StepInputRow extends StatelessWidget {
  const _StepInputRow({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    this.disableIncrease = false,
    this.warningText,
    this.dialogMaxValue,
    this.dialogConflictMessage,
    required this.buttonColor,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final bool disableIncrease;
  final String? warningText;
  final int? dialogMaxValue;
  final String? dialogConflictMessage;
  final Color buttonColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Future<void> editValue() async {
      String draftValue = value.toString();
      String? dialogErrorText;
      int fieldVersion = 0;

      final int? parsed = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              final ThemeData themed = Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: AppTokens.duckYellow,
                  selectionColor: AppTokens.duckYellow.withValues(alpha: 0.28),
                  selectionHandleColor: AppTokens.duckYellow,
                ),
              );
              return Theme(
                data: themed,
                child: AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  '输入$title',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      key: ValueKey<int>(fieldVersion),
                      autofocus: true,
                      initialValue: draftValue,
                      onChanged: (String text) {
                        draftValue = text;
                      },
                      keyboardType: TextInputType.number,
                      cursorColor: AppTokens.duckYellow,
                      decoration: const InputDecoration(
                        hintText: '请输入数字',
                        hintStyle: TextStyle(color: Color(0xFF8E8E8E)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTokens.duckYellow),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTokens.duckYellow, width: 2),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    if (dialogErrorText != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        dialogErrorText!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD64545),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final int? rawValue = int.tryParse(draftValue.trim());
                      if (rawValue == null) {
                        setDialogState(() {
                          dialogErrorText = '请输入有效数字';
                        });
                        return;
                      }

                      int next = rawValue.clamp(min, max).toInt();
                      final int effectiveDialogMax =
                          (dialogMaxValue ?? max).clamp(min, max).toInt();

                      if (next > effectiveDialogMax) {
                        setDialogState(() {
                          dialogErrorText =
                              dialogConflictMessage ?? '输入值超出可用范围，已回退到最大可用值';
                          draftValue = effectiveDialogMax.toString();
                          fieldVersion++;
                        });
                        return;
                      }

                      if (disableIncrease && next > value) {
                        next = value;
                      }
                      Navigator.of(context).pop(next);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.duckYellow,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确认'),
                  ),
                ],
                ),
              );
            },
          );
        },
      );
      if (parsed == null) {
        return;
      }
      int next = parsed.clamp(min, max).toInt();
      if (disableIncrease && next > value) {
        next = value;
      }
      onChanged(next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTokens.textMain, fontWeight: FontWeight.w700),
              ),
            ),
            _MiniStepButton(
              icon: Icons.remove,
              color: buttonColor,
              onTap: value > min ? () => onChanged(value - 1) : null,
            ),
            InkWell(
              onTap: editValue,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 30,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.textMain),
                ),
              ),
            ),
            _MiniStepButton(
              icon: Icons.add,
              color: buttonColor,
              onTap: (!disableIncrease && value < max) ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
        if (warningText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            warningText!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFD64545),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniStepButton extends StatelessWidget {
  const _MiniStepButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFD4D4D4) : color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _ScheduleConfig {
  _ScheduleConfig({
    required this.classDuration,
    required this.breakDuration,
    required this.termWeeks,
    required this.weekStartDay,
    required this.semesterStartDate,
    required this.morningSections,
    required this.afternoonSections,
    required this.eveningSections,
  });

  int classDuration;
  int breakDuration;
  int termWeeks;
  int weekStartDay;
  DateTime semesterStartDate;
  List<_SectionTime> morningSections;
  List<_SectionTime> afternoonSections;
  List<_SectionTime> eveningSections;

  List<_SectionTime> get sections => <_SectionTime>[
        ...morningSections,
        ...afternoonSections,
        ...eveningSections,
      ];

  int get morningCount => morningSections.length;
  int get afternoonCount => afternoonSections.length;
  int get eveningCount => eveningSections.length;

    _ScheduleConfig clone() {
    return _ScheduleConfig(
      classDuration: classDuration,
      breakDuration: breakDuration,
      termWeeks: termWeeks,
      weekStartDay: weekStartDay,
      semesterStartDate:
        DateTime.fromMillisecondsSinceEpoch(semesterStartDate.millisecondsSinceEpoch),
      morningSections: morningSections
        .map((item) => item.copyWith())
        .toList(growable: true),
      afternoonSections: afternoonSections
        .map((item) => item.copyWith())
        .toList(growable: true),
      eveningSections: eveningSections
        .map((item) => item.copyWith())
        .toList(growable: true),
    );
    }

    void overwriteFrom(_ScheduleConfig source) {
    classDuration = source.classDuration;
    breakDuration = source.breakDuration;
    termWeeks = source.termWeeks;
    weekStartDay = source.weekStartDay;
    semesterStartDate =
      DateTime.fromMillisecondsSinceEpoch(source.semesterStartDate.millisecondsSinceEpoch);
    morningSections = source.morningSections
      .map((item) => item.copyWith())
      .toList(growable: true);
    afternoonSections = source.afternoonSections
      .map((item) => item.copyWith())
      .toList(growable: true);
    eveningSections = source.eveningSections
      .map((item) => item.copyWith())
      .toList(growable: true);
    }

  set morningCount(int value) {
    _resizeSegment(
      segment: morningSections,
      target: value,
      defaultStart: '08:00',
    );
  }

  set afternoonCount(int value) {
    _resizeSegment(
      segment: afternoonSections,
      target: value,
      defaultStart: '14:00',
    );
  }

  set eveningCount(int value) {
    _resizeSegment(
      segment: eveningSections,
      target: value,
      defaultStart: '19:00',
    );
  }

  int get morningEnd => morningCount;
  int get afternoonStart => morningEnd + 1;
  int get afternoonEnd => morningEnd + afternoonCount;
  int get eveningStart => afternoonEnd + 1;
  int get eveningEnd => afternoonEnd + eveningCount;

  _SegmentAnchors captureAnchors() {
    return _SegmentAnchors(
      morningStart: morningSections.isEmpty ? '08:00' : morningSections.first.start,
      afternoonStart: afternoonSections.isEmpty ? '14:00' : afternoonSections.first.start,
      eveningStart: eveningSections.isEmpty ? '19:00' : eveningSections.first.start,
    );
  }

  void rebuildSectionsByAnchors(_SegmentAnchors anchors) {
    _alignSegment(morningSections, anchors.morningStart);
    _alignSegment(afternoonSections, anchors.afternoonStart);
    _alignSegment(eveningSections, anchors.eveningStart);
  }

  factory _ScheduleConfig.defaults() {
    final DateTime now = DateTime.now();
    return _ScheduleConfig(
      classDuration: 45,
      breakDuration: 10,
      termWeeks: 20,
      weekStartDay: 1,
      semesterStartDate: DateTime(now.year, 9, 2),
      morningSections: _buildSegment(
        count: 4,
        anchorStart: '08:00',
        classDuration: 45,
        breakDuration: 10,
      ),
      afternoonSections: _buildSegment(
        count: 4,
        anchorStart: '14:00',
        classDuration: 45,
        breakDuration: 10,
      ),
      eveningSections: _buildSegment(
        count: 2,
        anchorStart: '19:00',
        classDuration: 45,
        breakDuration: 10,
      ),
    );
  }

  factory _ScheduleConfig.fromJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return _ScheduleConfig.defaults();
    }
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      final _ScheduleConfig defaults = _ScheduleConfig.defaults();
      final int morning = (map['morningCount'] as int?) ?? (map['morningEnd'] as int?) ?? defaults.morningCount;
      final int afternoon = (map['afternoonCount'] as int?) ??
          ((map['afternoonEnd'] as int?) != null ? (map['afternoonEnd'] as int) - morning : defaults.afternoonCount);
      final int evening = (map['eveningCount'] as int?) ??
          ((map['eveningEnd'] as int?) != null
              ? (map['eveningEnd'] as int) - (morning + afternoon)
              : defaults.eveningCount);

      List<_SectionTime> morningSections = _parseSectionList(map['morningSections']);
      List<_SectionTime> afternoonSections = _parseSectionList(map['afternoonSections']);
      List<_SectionTime> eveningSections = _parseSectionList(map['eveningSections']);

      if (morningSections.isEmpty || afternoonSections.isEmpty || eveningSections.isEmpty) {
        final List<_SectionTime> legacy = _parseSectionList(map['sections']);
        if (legacy.isNotEmpty) {
          final int safeMorning = morning.clamp(1, legacy.length).toInt();
          final int safeAfternoon = afternoon.clamp(1, (legacy.length - safeMorning).clamp(1, legacy.length)).toInt();
          final int afternoonStart = safeMorning;
          final int afternoonEnd = (afternoonStart + safeAfternoon).clamp(afternoonStart, legacy.length).toInt();
          final int eveningStart = afternoonEnd;

          morningSections = legacy.sublist(0, safeMorning);
          afternoonSections = legacy.sublist(afternoonStart, afternoonEnd);
          eveningSections = eveningStart < legacy.length
              ? legacy.sublist(eveningStart)
              : <_SectionTime>[];
        }
      }

      final _ScheduleConfig parsed = _ScheduleConfig(
        classDuration: map['classDuration'] as int? ?? defaults.classDuration,
        breakDuration: map['breakDuration'] as int? ?? defaults.breakDuration,
        termWeeks: map['termWeeks'] as int? ?? defaults.termWeeks,
        weekStartDay: map['weekStartDay'] as int? ?? defaults.weekStartDay,
        semesterStartDate: DateTime.tryParse(map['semesterStartDate'] as String? ?? '') ??
            defaults.semesterStartDate,
        morningSections: morningSections.isEmpty
            ? _buildSegment(
                count: morning.clamp(1, 30).toInt(),
                anchorStart: '08:00',
                classDuration: map['classDuration'] as int? ?? defaults.classDuration,
                breakDuration: map['breakDuration'] as int? ?? defaults.breakDuration,
              )
            : morningSections,
        afternoonSections: afternoonSections.isEmpty
            ? _buildSegment(
                count: afternoon.clamp(1, 30).toInt(),
                anchorStart: '14:00',
                classDuration: map['classDuration'] as int? ?? defaults.classDuration,
                breakDuration: map['breakDuration'] as int? ?? defaults.breakDuration,
              )
            : afternoonSections,
        eveningSections: eveningSections.isEmpty
            ? _buildSegment(
                count: evening.clamp(1, 30).toInt(),
                anchorStart: '19:00',
                classDuration: map['classDuration'] as int? ?? defaults.classDuration,
                breakDuration: map['breakDuration'] as int? ?? defaults.breakDuration,
              )
            : eveningSections,
      );
      parsed.normalizeCounts();
      return parsed;
    } catch (_) {
      return _ScheduleConfig.defaults();
    }
  }

  String toJson() {
    return jsonEncode(<String, Object?>{
      'classDuration': classDuration,
      'breakDuration': breakDuration,
      'morningCount': morningCount,
      'afternoonCount': afternoonCount,
      'eveningCount': eveningCount,
      'morningEnd': morningEnd,
      'afternoonEnd': afternoonEnd,
      'eveningEnd': eveningEnd,
      'termWeeks': termWeeks,
      'weekStartDay': weekStartDay,
      'semesterStartDate': DateFormat('yyyy-MM-dd').format(semesterStartDate),
      'morningSections': morningSections
          .map((item) => <String, String>{
                'start': item.start,
                'end': item.end,
              })
          .toList(growable: false),
      'afternoonSections': afternoonSections
          .map((item) => <String, String>{
                'start': item.start,
                'end': item.end,
              })
          .toList(growable: false),
      'eveningSections': eveningSections
          .map((item) => <String, String>{
                'start': item.start,
                'end': item.end,
              })
          .toList(growable: false),
      'sections': sections
          .map((item) => <String, String>{
                'start': item.start,
                'end': item.end,
              })
          .toList(growable: false),
    });
  }

  void alignByTemplate() {
    _alignSegment(
      morningSections,
      morningSections.isEmpty ? '08:00' : morningSections.first.start,
    );
    _alignSegment(
      afternoonSections,
      afternoonSections.isEmpty ? '14:00' : afternoonSections.first.start,
    );
    _alignSegment(
      eveningSections,
      eveningSections.isEmpty ? '19:00' : eveningSections.first.start,
    );
  }

  void normalizeCounts() {
    if (morningSections.isEmpty) {
      morningSections = _buildSegment(
        count: 1,
        anchorStart: '08:00',
        classDuration: classDuration,
        breakDuration: breakDuration,
      );
    }
    if (afternoonSections.isEmpty) {
      afternoonSections = _buildSegment(
        count: 1,
        anchorStart: '14:00',
        classDuration: classDuration,
        breakDuration: breakDuration,
      );
    }
    if (eveningSections.isEmpty) {
      eveningSections = _buildSegment(
        count: 1,
        anchorStart: '19:00',
        classDuration: classDuration,
        breakDuration: breakDuration,
      );
    }
  }

  void setEveningCountPreferIncrease(int target) {
    eveningCount = target;
    normalizeCounts();
  }

  int maxMorningCountWithoutConflict() {
    if (morningSections.isEmpty || afternoonSections.isEmpty) {
      return 30;
    }
    return _maxCountByBoundary(
      anchorStart: morningSections.first.start,
      nextSegmentStart: afternoonSections.first.start,
    );
  }

  int maxAfternoonCountWithoutConflict() {
    if (afternoonSections.isEmpty || eveningSections.isEmpty) {
      return 30;
    }
    return _maxCountByBoundary(
      anchorStart: afternoonSections.first.start,
      nextSegmentStart: eveningSections.first.start,
    );
  }

  bool hasMorningAfternoonConflict() {
    if (morningSections.isEmpty || afternoonSections.isEmpty) {
      return false;
    }
    return _toMinutes(morningSections.last.end) >=
        _toMinutes(afternoonSections.first.start);
  }

  bool hasAfternoonEveningConflict() {
    if (afternoonSections.isEmpty || eveningSections.isEmpty) {
      return false;
    }
    return _toMinutes(afternoonSections.last.end) >=
        _toMinutes(eveningSections.first.start);
  }

  int _maxCountByBoundary({
    required String anchorStart,
    required String nextSegmentStart,
  }) {
    final int anchor = _toMinutes(anchorStart);
    final int nextStart = _toMinutes(nextSegmentStart);
    int allowed = 1;
    for (int count = 1; count <= 30; count++) {
      final int endMinutes = anchor + count * classDuration + (count - 1) * breakDuration;
      if (endMinutes >= nextStart) {
        return allowed.clamp(1, 30).toInt();
      }
      allowed = count;
    }
    return allowed.clamp(1, 30).toInt();
  }

  _SectionTime sectionAt(int globalIndex) {
    if (globalIndex < 0 || globalIndex >= sections.length) {
      throw RangeError.index(globalIndex, sections);
    }
    if (globalIndex < morningSections.length) {
      return morningSections[globalIndex];
    }
    final int afternoonIndex = globalIndex - morningSections.length;
    if (afternoonIndex < afternoonSections.length) {
      return afternoonSections[afternoonIndex];
    }
    final int eveningIndex = afternoonIndex - afternoonSections.length;
    return eveningSections[eveningIndex];
  }

  void updateSectionAt(int globalIndex, _SectionTime section) {
    if (globalIndex < 0 || globalIndex >= sections.length) {
      return;
    }
    if (globalIndex < morningSections.length) {
      morningSections[globalIndex] = section;
      return;
    }
    final int afternoonIndex = globalIndex - morningSections.length;
    if (afternoonIndex < afternoonSections.length) {
      afternoonSections[afternoonIndex] = section;
      return;
    }
    final int eveningIndex = afternoonIndex - afternoonSections.length;
    if (eveningIndex >= 0 && eveningIndex < eveningSections.length) {
      eveningSections[eveningIndex] = section;
    }
  }

  void _resizeSegment({
    required List<_SectionTime> segment,
    required int target,
    required String defaultStart,
  }) {
    final int desired = target.clamp(1, 30).toInt();
    if (segment.isEmpty) {
      segment.add(
        _SectionTime(
          start: defaultStart,
          end: _formatMinutes(_toMinutes(defaultStart) + classDuration),
        ),
      );
    }

    while (segment.length < desired) {
      final _SectionTime tail = segment.last;
      final int nextStart = _toMinutes(tail.end) + breakDuration;
      final int nextEnd = nextStart + classDuration;
      segment.add(
        _SectionTime(
          start: _formatMinutes(nextStart),
          end: _formatMinutes(nextEnd),
        ),
      );
    }

    if (segment.length > desired) {
      segment.removeRange(desired, segment.length);
    }
  }

  void _alignSegment(List<_SectionTime> segment, String anchorStart) {
    if (segment.isEmpty) {
      return;
    }
    int cursor = _toMinutes(anchorStart);
    for (int i = 0; i < segment.length; i++) {
      final int startMinutes = cursor;
      final int endMinutes = startMinutes + classDuration;
      segment[i] = _SectionTime(
        start: _formatMinutes(startMinutes),
        end: _formatMinutes(endMinutes),
      );
      cursor = endMinutes + breakDuration;
    }
  }

  static List<_SectionTime> _buildSegment({
    required int count,
    required String anchorStart,
    required int classDuration,
    required int breakDuration,
  }) {
    final int safeCount = count.clamp(1, 30).toInt();
    final List<_SectionTime> result = <_SectionTime>[];
    int cursor = _toMinutes(anchorStart);
    for (int i = 0; i < safeCount; i++) {
      final int startMinutes = cursor;
      final int endMinutes = startMinutes + classDuration;
      result.add(
        _SectionTime(
          start: _formatMinutes(startMinutes),
          end: _formatMinutes(endMinutes),
        ),
      );
      cursor = endMinutes + breakDuration;
    }
    return result;
  }

  static List<_SectionTime> _parseSectionList(dynamic raw) {
    final List<dynamic>? list = raw as List<dynamic>?;
    if (list == null || list.isEmpty) {
      return <_SectionTime>[];
    }
    return list
        .map((dynamic item) {
          final Map<String, dynamic> map = item as Map<String, dynamic>;
          return _SectionTime(
            start: map['start'] as String? ?? '08:00',
            end: map['end'] as String? ?? '08:45',
          );
        })
        .toList(growable: true);
  }

  static int _toMinutes(String hhmm) {
    final List<String> parts = hhmm.split(':');
    final int h = int.tryParse(parts.first) ?? 0;
    final int m = int.tryParse(parts.last) ?? 0;
    return h * 60 + m;
  }

  static String _formatMinutes(int total) {
    final int h = (total ~/ 60) % 24;
    final int m = total % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

class _SectionTime {
  const _SectionTime({required this.start, required this.end});

  final String start;
  final String end;

  _SectionTime copyWith({String? start, String? end}) {
    return _SectionTime(start: start ?? this.start, end: end ?? this.end);
  }
}

class _SegmentAnchors {
  const _SegmentAnchors({
    required this.morningStart,
    required this.afternoonStart,
    required this.eveningStart,
  });

  final String morningStart;
  final String afternoonStart;
  final String eveningStart;
}

class _ResolvedSlot {
  const _ResolvedSlot({required this.primary, required this.all, required this.active});

  const _ResolvedSlot.empty()
      : primary = null,
        all = const <CourseEntity>[],
        active = false;

  final CourseEntity? primary;
  final List<CourseEntity> all;
  final bool active;
}

class _RenderedCourseBlock {
  const _RenderedCourseBlock({
    required this.course,
    required this.dayColumn,
    required this.start,
    required this.span,
    required this.active,
    required this.detailCourses,
  });

  final CourseEntity course;
  final int dayColumn;
  final int start;
  final int span;
  final bool active;
  final List<CourseEntity> detailCourses;
}

class _CourseDragPayload {
  const _CourseDragPayload({
    required this.course,
    required this.courseId,
    required this.sourceDayColumn,
    required this.sourceStart,
    required this.timeCount,
    required this.weeks,
  });

  final CourseEntity course;
  final int? courseId;
  final int sourceDayColumn;
  final int sourceStart;
  final int timeCount;
  final List<int> weeks;
}

class _CourseDragHover {
  const _CourseDragHover({
    required this.dayColumn,
    required this.periodStart,
  });

  final int dayColumn;
  final int periodStart;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _CourseDragHover &&
        other.dayColumn == dayColumn &&
        other.periodStart == periodStart;
  }

  @override
  int get hashCode => Object.hash(dayColumn, periodStart);
}

class _CourseDropDecision {
  const _CourseDropDecision({
    required this.accepted,
    this.message,
  });

  final bool accepted;
  final String? message;
}

class _QuickAddSelection {
  const _QuickAddSelection({
    required this.anchorDay,
    required this.anchorPeriod,
    required this.currentDay,
    required this.currentPeriod,
  });

  final int anchorDay;
  final int anchorPeriod;
  final int currentDay;
  final int currentPeriod;

  int get dayStart => math.min(anchorDay, currentDay);
  int get dayEnd => math.max(anchorDay, currentDay);
  int get periodStart => math.min(anchorPeriod, currentPeriod);
  int get periodEnd => math.max(anchorPeriod, currentPeriod);

  _QuickAddSelection copyWith({
    int? currentDay,
    int? currentPeriod,
  }) {
    return _QuickAddSelection(
      anchorDay: anchorDay,
      anchorPeriod: anchorPeriod,
      currentDay: currentDay ?? this.currentDay,
      currentPeriod: currentPeriod ?? this.currentPeriod,
    );
  }
}

class _AddMenuItem extends StatelessWidget {
  const _AddMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: const Color(0x26000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: SizedBox(
        width: 136,
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const Spacer(),
            Container(
              width: 2,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      ),
    );
  }
}

