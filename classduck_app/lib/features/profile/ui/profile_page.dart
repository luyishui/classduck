import 'package:flutter/material.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/duck_modal.dart';
import '../../schedule/domain/course.dart';
import '../../schedule/domain/course_table.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../settings/ui/about_page.dart';
import '../../settings/ui/appearance_page.dart';
import '../../settings/ui/notifications_page.dart';
import '../../todo/data/todo_repository.dart';
import '../../todo/domain/todo_item.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final TodoRepository _todoRepository = TodoRepository();

  int _doneCourseCount = 0;
  int _doneTodoCount = 0;
  String _todayMoodLabel = '很棒';
  bool _loading = false;
  DateTime? _lastStatsLoadedAt;

  final List<String> _moodOptions = <String>['很棒', '专注', '平静'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
    });

    final int courseCount = await _scheduleRepository.getDoneCourseCount();
    final int todoDoneCount = (await _todoRepository.getTodos(completed: true)).length;

    if (!mounted) {
      return;
    }

    setState(() {
      _doneCourseCount = courseCount;
      _doneTodoCount = todoDoneCount;
      _loading = false;
      _lastStatsLoadedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    _refreshStatsIfNeeded();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 120),
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      '我的鸭窝',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '上课鸭',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTokens.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              _TopActionButton(
                icon: Icons.share_outlined,
                onTap: _openSharePlaceholder,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _StatBlock(
                    label: '已上课程',
                    value: _loading ? '...' : _doneCourseCount.toString(),
                    highlightColor: const Color(0xFF40352A),
                    onTap: _openDoneCourseModal,
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatBlock(
                    label: '完成待办',
                    value: _loading ? '...' : _doneTodoCount.toString(),
                    highlightColor: const Color(0xFFD19B00),
                    onTap: _openDoneTodoModal,
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatBlock(
                    label: '今日状态',
                    value: _todayMoodLabel,
                    highlightColor: const Color(0xFF6FA75A),
                    onTap: _openMoodModal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '设置',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFB2A592),
                ),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            title: '外观与主题',
            onTap: () => _openPage(const AppearancePage()),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            title: '提醒与通知',
            onTap: () => _openPage(const NotificationsPage()),
          ),
          const SizedBox(height: 8),
          _SettingCard(
            title: '关于上课鸭',
            onTap: () => _openPage(const AboutPage()),
          ),
        ],
      ),
    );
  }

  void _refreshStatsIfNeeded() {
    final DateTime now = DateTime.now();
    if (_loading) {
      return;
    }
    if (_lastStatsLoadedAt != null && now.difference(_lastStatsLoadedAt!) < const Duration(seconds: 3)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadStats();
      }
    });
  }

  Future<void> _openSharePlaceholder() async {
    await DuckModal.show<void>(
      context: context,
      child: const DuckModalFrame(
        title: '分享',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppTokens.space12),
          child: Text('分享能力会在后续任务接入。'),
        ),
      ),
    );
  }

  Future<void> _openDoneCourseModal() async {
    await _loadStats();
    // 只读弹窗：按课表分组展示“已上课程”，不在此处提供编辑能力。
    final Map<String, List<String>> groups = await _buildDoneCourseGroups();
    if (!mounted) {
      return;
    }

    await _showReadonlyGroupedModal(
      title: '已上课程',
      emptyText: '暂无已上课程',
      groups: groups,
    );
  }

  Future<void> _openDoneTodoModal() async {
    await _loadStats();
    // 只读弹窗：按任务类型分组展示“已完成待办”。
    final List<TodoItem> doneTodos = await _todoRepository.getTodos(completed: true);
    final Map<String, List<String>> groups = <String, List<String>>{
      '作业': <String>[],
      '考试': <String>[],
      '竞赛': <String>[],
    };

    for (final TodoItem todo in doneTodos) {
      final String key = switch (todo.taskType) {
        'assignment' => '作业',
        'exam' => '考试',
        'contest' => '竞赛',
        _ => todo.taskType,
      };
      groups.putIfAbsent(key, () => <String>[]).add(todo.title);
    }

    if (!mounted) {
      return;
    }

    await _showReadonlyGroupedModal(
      title: '已完成待办',
      emptyText: '暂无已完成待办',
      groups: groups,
    );
  }

  Future<void> _openMoodModal() async {
    // 弹窗内使用 pending 值，只有关闭时才正式回写主页，避免误触即提交。
    String keyword = '';
    bool creating = false;
    String custom = '';
    String pending = _todayMoodLabel;

    await DuckModal.show<void>(
      context: context,
      barrierColor: const Color(0x66000000),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Material(
            color: Colors.transparent,
            child: Container(
              width: 336,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: AppTokens.pageBackground,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x2B000000),
                    blurRadius: 52,
                    offset: Offset(0, 22),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _todayMoodLabel = pending;
                          });
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF8F8A84)),
                      ),
                      const Expanded(
                        child: Text(
                          '今日状态',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTokens.textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1EC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      onChanged: (String value) {
                        setModalState(() {
                          keyword = value.trim();
                        });
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '搜索心情...',
                        icon: Icon(Icons.search, color: AppTokens.textMuted, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 198,
                    child: ListView(
                      children: _moodOptions
                          .where((String mood) => mood.contains(keyword))
                          .map(
                            (String mood) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _MoodOptionTile(
                                label: mood,
                                active: pending == mood,
                                onTap: () {
                                  setModalState(() {
                                    pending = mood;
                                  });
                                },
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  if (creating)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6DD),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: TextField(
                                onChanged: (String value) {
                                  custom = value.trim();
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '自定义名称',
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (custom.isEmpty || _moodOptions.contains(custom)) {
                                return;
                              }
                              setState(() {
                                _moodOptions.add(custom);
                                _todayMoodLabel = custom;
                              });
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.check_circle, color: AppTokens.duckYellow),
                          ),
                          IconButton(
                            onPressed: () {
                              setModalState(() {
                                creating = false;
                              });
                            },
                            icon: const Icon(Icons.cancel, color: AppTokens.textMuted),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        setModalState(() {
                          creating = true;
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.duckYellow,
                        foregroundColor: AppTokens.textMain,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text('新建心情'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, List<String>>> _buildDoneCourseGroups() async {
    // 按“课表 -> 课程项”组织数据，便于对应 PRD 的分组抽屉结构。
    final List<CourseTableEntity> tables = await _scheduleRepository.getCourseTables();
    final Map<String, List<String>> groups = <String, List<String>>{};

    for (final CourseTableEntity table in tables) {
      if (table.id == null) {
        continue;
      }

      final List<CourseEntity> courses = await _scheduleRepository.getCoursesByTableId(table.id!);
      final List<String> doneNames = courses
          .where(_isCourseDone)
          .map((CourseEntity c) => c.name)
          .toSet()
          .toList(growable: false);

      groups[table.name] = doneNames;
    }

    return groups;
  }

  bool _isCourseDone(CourseEntity course) {
    // 课程是否“已上完”的简化判定：在当前工作日和节次之前即视为已完成。
    final DateTime now = DateTime.now();
    final int nowDay = now.weekday;
    final int nowPeriod = _guessCurrentPeriod(now);
    final int endPeriod = course.startTime + course.timeCount;
    return course.weekTime < nowDay || (course.weekTime == nowDay && endPeriod < nowPeriod);
  }

  int _guessCurrentPeriod(DateTime now) {
    final int hm = now.hour * 100 + now.minute;
    if (hm < 800) return 0;
    if (hm <= 845) return 1;
    if (hm <= 940) return 2;
    if (hm <= 1045) return 3;
    if (hm <= 1145) return 4;
    if (hm <= 1445) return 5;
    if (hm <= 1545) return 6;
    if (hm <= 1645) return 7;
    if (hm <= 1745) return 8;
    return 99;
  }

  Future<void> _showReadonlyGroupedModal({
    required String title,
    required String emptyText,
    required Map<String, List<String>> groups,
  }) {
    return DuckModal.show<void>(
      context: context,
      barrierColor: const Color(0x66000000),
      child: _ReadonlyGroupedModal(
        title: title,
        emptyText: emptyText,
        groups: groups,
      ),
    );
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (BuildContext context) => page),
    );
    await _loadStats();
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5D6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF40352A), size: 20),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFF1E9DA),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.highlightColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color highlightColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: highlightColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFFB2A592)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodOptionTile extends StatelessWidget {
  const _MoodOptionTile({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFFFF6DD) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 54,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTokens.textMain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadonlyGroupedModal extends StatefulWidget {
  const _ReadonlyGroupedModal({
    required this.title,
    required this.emptyText,
    required this.groups,
  });

  final String title;
  final String emptyText;
  final Map<String, List<String>> groups;

  @override
  State<_ReadonlyGroupedModal> createState() => _ReadonlyGroupedModalState();
}

class _ReadonlyGroupedModalState extends State<_ReadonlyGroupedModal> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expanded = <String>{};
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> filtered = <String, List<String>>{};

    widget.groups.forEach((String group, List<String> items) {
      if (_keyword.isEmpty) {
        filtered[group] = items;
        return;
      }

      final bool matchGroup = group.contains(_keyword);
      final List<String> matchItems = items.where((String item) => item.contains(_keyword)).toList();
      if (matchGroup || matchItems.isNotEmpty) {
        filtered[group] = matchGroup ? items : matchItems;
      }
    });

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 336,
        height: 476,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: AppTokens.pageBackground,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, color: AppTokens.textMuted),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (String value) {
                  setState(() {
                    _keyword = value.trim();
                  });
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, size: 18, color: AppTokens.textMuted),
                  hintText: '搜索',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyText,
                        style: const TextStyle(color: AppTokens.textMuted),
                      ),
                    )
                  : ListView(
                      children: filtered.entries.map((MapEntry<String, List<String>> entry) {
                        final bool opened = _expanded.contains(entry.key);
                        final List<String> preview = opened
                            ? entry.value
                            : entry.value.take(3).toList(growable: false);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            children: <Widget>[
                              Material(
                                color: opened ? const Color(0xFFFFF6DD) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      if (opened) {
                                        _expanded.remove(entry.key);
                                      } else {
                                        _expanded.add(entry.key);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(
                                              color: AppTokens.textMain,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          opened
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          color: AppTokens.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (opened)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: preview
                                        .map(
                                          (String item) => Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              children: <Widget>[
                                                const Icon(
                                                  Icons.circle,
                                                  size: 6,
                                                  color: AppTokens.textMuted,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    item,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppTokens.textMain,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF40352A),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFC6BBA8)),
            ],
          ),
        ),
      ),
    );
  }
}
