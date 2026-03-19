import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

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
          _courses = const <CourseEntity>[];
        });
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
    final String dateText = DateFormat('yyyy年M月d日').format(now);
    final int viewingWeek = _effectiveDisplayWeek(config);
    final List<DateTime> weekDates = _weekDatesForDisplay(config, viewingWeek);
    final String weekText = _currentWeek <= 0 ? '未开学' : '第 $viewingWeek 周';
    final bool viewingOtherWeek = _currentWeek > 0 && viewingWeek != _currentWeek;
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
    setState(() {
      _addMenuOpen = !_addMenuOpen;
    });
  }

  Future<void> _handleAddMenuAction(String action) async {
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

    Future<void> pickTime({required int index, required bool start}) async {
      final _ScheduleConfig config = _activeConfig();
      if (index < 0 || index >= config.sections.length) {
        return;
      }
      final String source = start ? config.sections[index].start : config.sections[index].end;
      final String? pickedValue = await _openTimeEditDialog(context, source);
      if (pickedValue == null) {
        return;
      }
      await updateConfig((config) {
        final String value = pickedValue;
        final _SectionTime current = config.sections[index];
        final String nextStart = start ? value : current.start;
        final String nextEnd = start
            ? _formatMinute(_toMinute(value) + config.classDuration)
            : value;
        if (_toMinute(nextStart) >= _toMinute(nextEnd)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('上课时间必须早于下课时间')),
          );
          return;
        }

        // 联动规则：
        // 1) 改开始时间 -> 本节结束按课时时长自动推算
        // 2) 改结束时间 -> 保留本节开始，结束按用户输入
        // 3) 后续节次按“上一节结束 + 课间时长 + 课时时长”整体顺延
        if (start) {
          config.sections[index] = current.copyWith(start: nextStart, end: nextEnd);
        } else {
          config.sections[index] = current.copyWith(end: nextEnd);
        }

        int cursor = _toMinute(config.sections[index].end) + config.breakDuration;
        for (int i = index + 1; i < config.sections.length; i++) {
          final String autoStart = _formatMinute(cursor);
          final String autoEnd = _formatMinute(cursor + config.classDuration);
          config.sections[i] = config.sections[i].copyWith(start: autoStart, end: autoEnd);
          cursor = _toMinute(autoEnd) + config.breakDuration;
        }
      });
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
                                  await pickTime(index: section - 1, start: true);
                                  setModalState(() {});
                                },
                                child: Container(
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7E3DC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    config.sections[section - 1].start,
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
                                  await pickTime(index: section - 1, start: false);
                                  setModalState(() {});
                                },
                                child: Container(
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7E3DC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    config.sections[section - 1].end,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: AppTokens.textMain),
                                  ),
                                ),
                              ),
                            ),
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
                                    max: 8,
                                    buttonColor: const Color(0xFFF2A866),
                                    onChanged: (int value) async {
                                      await updateConfig((config) {
                                        config.morningCount = value;
                                        config.normalizeCounts();
                                      });
                                      setModalState(() {});
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
                                    max: (10 - config.morningCount - 1).clamp(1, 8).toInt(),
                                    buttonColor: const Color(0xFFE5A15A),
                                    onChanged: (int value) async {
                                      await updateConfig((config) {
                                        config.afternoonCount = value;
                                        config.normalizeCounts();
                                      });
                                      setModalState(() {});
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
                                    max: 8,
                                    buttonColor: const Color(0xFFD37F95),
                                    onChanged: (int value) async {
                                      await updateConfig((config) {
                                        config.setEveningCountPreferIncrease(value);
                                      });
                                      setModalState(() {});
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
                                      style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
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
      final List<TodoItem> linkedTodos = await _todoRepository.getTodosByCourseName(course.name);
      todoByCourseName[course.name] = linkedTodos;
    }

    if (!mounted) {
      return;
    }

    await DuckModal.show<void>(
      context: context,
      child: _CourseActivatedModal(
        courses: courses,
        todoByCourseName: todoByCourseName,
        onDelete: (int index) async {
          final CourseEntity course = courses[index];
          final int? courseId = course.id;
          if (courseId == null) {
            return;
          }

          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('删除课程'),
                content: Text('确认删除课程“${course.name}”吗？'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('删除'),
                  ),
                ],
              );
            },
          );

          if (confirmed != true) {
            return;
          }

          await _scheduleRepository.deleteCourse(courseId);
          await _loadScheduleData();

          if (!mounted) {
            return;
          }
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除课程：${course.name}')),
          );
        },
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
    final Map<String, Color> colorMap = <String, Color>{
      for (final CourseEntity item in _courses) item.name: _colorForCourseName(item.name),
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

                        return Stack(
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
                            for (final _RenderedCourseBlock block in blocks)
                              _buildCourseCard(
                                block: block,
                                colWidth: colWidth,
                                rowHeight: rowHeight,
                                color: colorMap[block.course.name] ?? _colorForCourseName(block.course.name),
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
    final int day = course.weekTime.clamp(1, 7);
    final int start = block.start.clamp(1, _periodTimes.length);
    final int span = block.span.clamp(1, 4);
    final Color activeColor = _normalizeCourseDisplayColor(color);
    final Color finalColor = block.active ? activeColor : const Color(0xFFE1DED7);
    const Color titleColor = Color(0xFF1F1A14);
    const Color metaColor = Color(0xFF1F1A14);

    return Positioned(
      left: (day - 1) * colWidth + 2,
      top: (start - 1) * rowHeight + 3,
      width: colWidth - 4,
      height: rowHeight * span - 6,
      child: GestureDetector(
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
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
            decoration: BoxDecoration(
              color: finalColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: Text(
                      course.name,
                      maxLines: span >= 2 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
                Text(
                  course.teacher?.isNotEmpty == true ? course.teacher! : '未填教师',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    color: metaColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  course.classroom?.isNotEmpty == true ? course.classroom! : '未填地点',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    color: metaColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_RenderedCourseBlock> _buildRenderedBlocks(List<CourseEntity> source) {
    final List<_RenderedCourseBlock> result = <_RenderedCourseBlock>[];

    for (int day = 1; day <= 7; day++) {
      final List<_ResolvedSlot> slots = List<_ResolvedSlot>.generate(
        _periodTimes.length + 1,
        (int _) => const _ResolvedSlot.empty(),
      );

      for (int period = 1; period <= _periodTimes.length; period++) {
        final List<CourseEntity> active = source
            .where((CourseEntity c) =>
            c.weekTime == day && _coversPeriod(c, period) && _isCourseInDisplayedWeek(c))
            .toList(growable: false)
          ..sort((CourseEntity a, CourseEntity b) => a.name.compareTo(b.name));

        if (active.isNotEmpty) {
          slots[period] = _ResolvedSlot(primary: active.first, all: active, active: true);
          continue;
        }

        final List<CourseEntity> inactive = source
            .where((CourseEntity c) =>
            c.weekTime == day && _coversPeriod(c, period) && !_isCourseInDisplayedWeek(c))
            .toList(growable: false)
          ..sort((CourseEntity a, CourseEntity b) => a.name.compareTo(b.name));

        if (inactive.isNotEmpty) {
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

  Future<String?> _openTimeEditDialog(BuildContext context, String initialValue) async {
    final List<String> parts = initialValue.split(':');
    int hour = int.tryParse(parts.first) ?? 8;
    int minute = int.tryParse(parts.last) ?? 0;

    final TextEditingController hourController = TextEditingController(
      text: hour.toString().padLeft(2, '0'),
    );
    final TextEditingController minuteController = TextEditingController(
      text: minute.toString().padLeft(2, '0'),
    );

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

            return AlertDialog(
              title: const Text('时间设置'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (!wheelMode)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: hourController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '小时',
                                hintText: '00-23',
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
                              decoration: const InputDecoration(
                                labelText: '分钟',
                                hintText: '00-59',
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
                                scrollController: FixedExtentScrollController(initialItem: hour),
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
                                scrollController: FixedExtentScrollController(initialItem: minute),
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
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!wheelMode && !applyManualInput()) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                    );
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    hourController.dispose();
    minuteController.dispose();
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
    required this.onDelete,
  });

  final List<CourseEntity> courses;
  final Map<String, List<TodoItem>> todoByCourseName;
  final Future<void> Function(int index) onDelete;

  @override
  State<_CourseActivatedModal> createState() => _CourseActivatedModalState();
}

class _CourseActivatedModalState extends State<_CourseActivatedModal> {
  int _index = 0;

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

  @override
  Widget build(BuildContext context) {
    final List<CourseEntity> courses = widget.courses;
    final CourseEntity course = courses[_index];
    final List<TodoItem> linkedTodos = widget.todoByCourseName[course.name] ?? const <TodoItem>[];

    return Material(
      color: Colors.transparent,
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
            Row(
              children: <Widget>[
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(Icons.close, size: 18, color: Color(0xFF9F9488)),
                  ),
                ),
                Expanded(
                  child: Text(
                    course.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.textMain,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onDelete(_index),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(Icons.delete_outline, size: 18, color: Color(0xFFE16C7B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CourseInfoLine(label: '星期', value: _weekdayText(course.weekTime)),
            _CourseInfoLine(label: '节次', value: '第${course.startTime}-${course.startTime + course.timeCount - 1}节'),
            _CourseInfoLine(label: '周数', value: _weekRangeText(course.weeksJson)),
            _CourseInfoLine(label: '教师', value: course.teacher?.isNotEmpty == true ? course.teacher! : '未填写'),
            _CourseInfoLine(label: '地点', value: course.classroom?.isNotEmpty == true ? course.classroom! : '未填写'),
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
            const SizedBox(height: 8),
            if (linkedTodos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '暂无关联待办',
                  style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
                ),
              )
            else
              ...linkedTodos.take(3).map((TodoItem item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1E9DA)),
                    ),
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTokens.textMain,
                      ),
                    ),
                  ),
                );
              }),
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
                              ? const Color(0xFF7B6D5B)
                              : const Color(0xFFBFB4A7),
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
                              ? const Color(0xFF7B6D5B)
                              : const Color(0xFFBFB4A7),
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
            ],
          ),
        ),
      ),
    );
  }

  static String _weekdayText(int weekDay) {
    switch (weekDay) {
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
      case 7:
        return '日';
      default:
        return '-';
    }
  }

  static String _weekRangeText(String weeksJson) {
    try {
      final List<dynamic> raw = jsonDecode(weeksJson) as List<dynamic>;
      final List<int> weeks = raw
          .whereType<num>()
          .map((num item) => item.toInt())
          .where((int value) => value > 0)
          .toList(growable: false)
        ..sort();
      if (weeks.isEmpty) {
        return '未填写';
      }
      return '第${weeks.first}-${weeks.last}周';
    } catch (_) {
      return '未填写';
    }
  }
}

class _CourseInfoLine extends StatelessWidget {
  const _CourseInfoLine({required this.label, required this.value});

  final String label;
  final String value;

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
                color: const Color(0xFFF8F5EF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 12, color: AppTokens.textMain),
              ),
            ),
          ),
        ],
      ),
    );
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
    required this.buttonColor,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final Color buttonColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Future<void> editValue() async {
      final TextEditingController controller = TextEditingController(text: '$value');
      final int? parsed = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('输入$title'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '请输入数字'),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  final int? value = int.tryParse(controller.text.trim());
                  Navigator.of(context).pop(value);
                },
                child: const Text('确认'),
              ),
            ],
          );
        },
      );
      controller.dispose();
      if (parsed == null) {
        return;
      }
      onChanged(parsed.clamp(min, max).toInt());
    }

    return Row(
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
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
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
    required this.morningCount,
    required this.afternoonCount,
    required this.eveningCount,
    required this.termWeeks,
    required this.weekStartDay,
    required this.semesterStartDate,
    required this.sections,
  });

  int classDuration;
  int breakDuration;
  int morningCount;
  int afternoonCount;
  int eveningCount;
  int termWeeks;
  int weekStartDay;
  DateTime semesterStartDate;
  List<_SectionTime> sections;

  int get morningEnd => morningCount;
  int get afternoonStart => morningEnd + 1;
  int get afternoonEnd => morningEnd + afternoonCount;
  int get eveningStart => afternoonEnd + 1;
  int get eveningEnd => afternoonEnd + eveningCount;

  factory _ScheduleConfig.defaults() {
    final DateTime now = DateTime.now();
    return _ScheduleConfig(
      classDuration: 45,
      breakDuration: 10,
      morningCount: 4,
      afternoonCount: 4,
      eveningCount: 2,
      termWeeks: 20,
      weekStartDay: 1,
      semesterStartDate: DateTime(now.year, 9, 2),
      sections: <_SectionTime>[
        const _SectionTime(start: '08:00', end: '08:45'),
        const _SectionTime(start: '08:55', end: '09:40'),
        const _SectionTime(start: '10:00', end: '10:45'),
        const _SectionTime(start: '11:00', end: '11:45'),
        const _SectionTime(start: '14:00', end: '14:45'),
        const _SectionTime(start: '15:00', end: '15:45'),
        const _SectionTime(start: '16:00', end: '16:45'),
        const _SectionTime(start: '17:00', end: '17:45'),
        const _SectionTime(start: '19:00', end: '19:45'),
        const _SectionTime(start: '19:55', end: '20:40'),
      ],
    );
  }

  factory _ScheduleConfig.fromJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return _ScheduleConfig.defaults();
    }
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> sectionRaw = (map['sections'] as List<dynamic>? ?? <dynamic>[]);
      final List<_SectionTime> sections = sectionRaw
          .map((dynamic item) => _SectionTime(
                start: (item as Map<String, dynamic>)['start'] as String? ?? '08:00',
                end: item['end'] as String? ?? '08:45',
              ))
          .toList(growable: false);
      final _ScheduleConfig defaults = _ScheduleConfig.defaults();
      final int morning = map['morningCount'] as int? ?? (map['morningEnd'] as int? ?? defaults.morningCount);
        final int afternoon = map['afternoonCount'] as int? ??
          (((map['afternoonEnd'] as int? ?? defaults.afternoonEnd) - morning).clamp(1, 8).toInt());
        final int evening = map['eveningCount'] as int? ??
          (((map['eveningEnd'] as int? ?? defaults.eveningEnd) - (morning + afternoon)).clamp(1, 8).toInt());
      return _ScheduleConfig(
        classDuration: map['classDuration'] as int? ?? defaults.classDuration,
        breakDuration: map['breakDuration'] as int? ?? defaults.breakDuration,
        morningCount: morning,
        afternoonCount: afternoon,
        eveningCount: evening,
        termWeeks: map['termWeeks'] as int? ?? defaults.termWeeks,
        weekStartDay: map['weekStartDay'] as int? ?? defaults.weekStartDay,
        semesterStartDate: DateTime.tryParse(map['semesterStartDate'] as String? ?? '') ??
            defaults.semesterStartDate,
        sections: sections.length == 10 ? sections : defaults.sections,
      )..normalizeCounts();
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
      'sections': sections
          .map((item) => <String, String>{
                'start': item.start,
                'end': item.end,
              })
          .toList(growable: false),
    });
  }

  void alignByTemplate() {
    if (sections.length != 10) {
      return;
    }

    final List<_SectionTime> rebuilt = List<_SectionTime>.from(sections);

    void alignRange(int fromIndex, int toIndex) {
      int cursorMinutes = _toMinutes(sections[fromIndex].start);
      for (int i = fromIndex; i <= toIndex; i++) {
        final int startMinutes = cursorMinutes;
        final int endMinutes = startMinutes + classDuration;
        rebuilt[i] = _SectionTime(
          start: _formatMinutes(startMinutes),
          end: _formatMinutes(endMinutes),
        );
        cursorMinutes = endMinutes + breakDuration;
      }
    }

    // 仅在各时段内部对齐：保留上午/下午/晚上之间的休息断层。
    alignRange(0, morningEnd - 1);
    alignRange(afternoonStart - 1, afternoonEnd - 1);
    alignRange(eveningStart - 1, eveningEnd - 1);

    sections = rebuilt;
  }

  void normalizeCounts() {
    morningCount = morningCount.clamp(1, 8).toInt();
    final int maxAfternoon = (10 - morningCount - 1).clamp(1, 8).toInt();
    afternoonCount = afternoonCount.clamp(1, maxAfternoon).toInt();
    final int maxEvening = (10 - morningCount - afternoonCount).clamp(1, 10).toInt();
    eveningCount = eveningCount.clamp(1, maxEvening).toInt();
  }

  void setEveningCountPreferIncrease(int target) {
    final int desired = target.clamp(1, 8).toInt();
    if (desired <= eveningCount) {
      eveningCount = desired;
      normalizeCounts();
      return;
    }

    int delta = desired - eveningCount;
    while (delta > 0) {
      if (afternoonCount > 1) {
        afternoonCount -= 1;
        eveningCount += 1;
        delta -= 1;
        continue;
      }
      if (morningCount > 1) {
        morningCount -= 1;
        eveningCount += 1;
        delta -= 1;
        continue;
      }
      break;
    }

    normalizeCounts();
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
    required this.start,
    required this.span,
    required this.active,
    required this.detailCourses,
  });

  final CourseEntity course;
  final int start;
  final int span;
  final bool active;
  final List<CourseEntity> detailCourses;
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

