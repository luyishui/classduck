import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/duck_modal.dart';
import '../../schedule/domain/course.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/domain/course_table.dart';
import '../data/todo_repository.dart';
import '../domain/todo_item.dart';
import 'new_todo_page.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage>
    with SingleTickerProviderStateMixin {
  final TodoRepository _repository = TodoRepository();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  late final TabController _tabController;

  bool _loading = false;
  String? _error;
  List<TodoItem> _pending = const <TodoItem>[];
  List<TodoItem> _completed = const <TodoItem>[];

  final Map<String, bool> _pendingExpanded = <String, bool>{
    'assignment': false,
    'exam': false,
    'contest': false,
  };

  final Map<String, bool> _completedExpanded = <String, bool>{
    'assignment': false,
    'exam': false,
    'contest': false,
  };

  final List<String> _typeOrder = <String>[
    'assignment',
    'exam',
    'contest',
  ];

  final Map<String, String> _typeLabels = <String, String>{
    'assignment': '作业',
    'exam': '考试',
    'contest': '竞赛',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<TodoItem> pending = await _repository.getTodos(completed: false);
      final List<TodoItem> completed = await _repository.getTodos(completed: true);

      setState(() {
        _pending = pending;
        _completed = completed;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _TopActionButton(icon: Icons.menu, onTap: _openSidebarPlaceholder),
                        const Expanded(
                          child: Text(
                            '待办',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.textMain,
                            ),
                          ),
                        ),
                        _TopActionButton(
                          icon: Icons.share_outlined,
                          onTap: _openSharePlaceholder,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '今天也要把作业和考试安排得明明白白',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTokens.textMuted,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: const Color(0xFFFFF0C9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: const Color(0xFF40352A),
                        unselectedLabelColor: const Color(0xFFB2A592),
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        unselectedLabelStyle:
                            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        tabs: const <Widget>[
                          Tab(text: '未完成'),
                          Tab(text: '已完成'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildError()
                        : TabBarView(
                            controller: _tabController,
                            children: <Widget>[
                              _buildTodoTab(items: _pending, completed: false),
                              _buildTodoTab(items: _completed, completed: true),
                            ],
                          ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 108,
            child: FloatingActionButton(
              heroTag: 'todo-fab',
              onPressed: _openNewTodo,
              backgroundColor: AppTokens.duckYellow,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('待办加载失败：$_error'),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoTab({required List<TodoItem> items, required bool completed}) {
    // 未完成与已完成使用独立展开状态，避免切换分栏时抽屉状态相互污染。
    final Map<String, bool> expandedMap = completed ? _completedExpanded : _pendingExpanded;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 6, 28, 120),
        children: <Widget>[
          for (final String type in _typeOrder) ...<Widget>[
            _buildGroupHeader(
              type: type,
              expanded: expandedMap[type] ?? false,
              count: items.where((TodoItem item) => item.taskType == type).length,
              onToggle: () {
                setState(() {
                  expandedMap[type] = !(expandedMap[type] ?? false);
                });
              },
            ),
            ..._buildGroupItems(
              type: type,
              items: items,
              expanded: expandedMap[type] ?? false,
              completed: completed,
            ),
            const SizedBox(height: 8),
          ],
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '暂无待办',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB2A592)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader({
    required String type,
    required bool expanded,
    required int count,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: <Widget>[
            Text(
              _typeTitle(type),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF40352A),
              ),
            ),
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '$count',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB2A592)),
                ),
              ),
            const Spacer(),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: const Color(0xFFB2A592),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupItems({
    required String type,
    required List<TodoItem> items,
    required bool expanded,
    required bool completed,
  }) {
    final List<TodoItem> grouped = items
        .where((TodoItem item) => item.taskType == type)
        .toList(growable: false);

    if (grouped.isEmpty) {
      return <Widget>[];
    }

    final List<TodoItem> visible = expanded ? grouped : const <TodoItem>[];

    return visible
        .map((TodoItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TodoCard(
                item: item,
                completed: completed,
                onToggle: (bool value) => _toggleCompleted(item, value),
                onDelete: () => _delete(item),
              ),
            ))
        .toList(growable: false);
  }

  Future<void> _openNewTodo() async {
    final List<String> latestCourseOptions = await _loadCourseOptions();
    if (!mounted) {
      return;
    }

    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => NewTodoPage(
          taskTypeLabels: Map<String, String>.from(_typeLabels),
          courseOptions: List<String>.from(latestCourseOptions),
        ),
      ),
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _toggleCompleted(TodoItem item, bool completed) async {
    // 数据层只切换完成态，列表迁移由 reload 后的分栏查询自然完成。
    await _repository.updateCompleted(id: item.id!, isCompleted: completed);
    await _load();
  }

  Future<void> _delete(TodoItem item) async {
    await _repository.deleteTodo(item.id!);
    await _load();
  }

  String _typeTitle(String type) {
    return _typeLabels[type] ?? type;
  }

  Future<List<String>> _loadCourseOptions() async {
    final List<CourseTableEntity> tables = await _scheduleRepository.getCourseTables();
    final Set<String> names = <String>{};

    final List<Future<List<CourseEntity>>> tasks = <Future<List<CourseEntity>>>[];
    for (final CourseTableEntity table in tables) {
      final int? tableId = table.id;
      if (tableId == null) {
        continue;
      }
      tasks.add(_scheduleRepository.getCoursesByTableId(tableId));
    }

    final List<List<CourseEntity>> allCourses = await Future.wait(tasks);
    for (final List<CourseEntity> courses in allCourses) {
      for (final item in courses) {
        final String name = item.name.trim();
        if (name.isNotEmpty) {
          names.add(name);
        }
      }
    }
    return names.toList(growable: false);
  }

  Future<void> _openSidebarPlaceholder() async {
    // PRD 状态机：
    // - sidebar_open_normal: editingType=false，只展示分组与“+ 新建待办”
    // - sidebar_open_editing: editingType=true，插入输入行 + 勾叉操作
    // 关闭侧栏即销毁局部编辑态，等价于“取消临时编辑”。
    final TextEditingController controller = TextEditingController(text: '自定义名称');
    bool editingType = false;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'todo-sidebar',
      barrierColor: const Color(0x66000000),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (
        BuildContext dialogContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> confirmCreateType() async {
              // 对齐 PRD：确认前需做非空和重名校验。
              final String name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入类型名称')),
                );
                return;
              }
              if (_typeLabels.containsValue(name)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('该类型已存在')),
                );
                return;
              }

              final String key = name;
              setState(() {
                // 对齐 PRD 联动：新增类型后，同步影响主页面分组和新建待办类型集合。
                _typeOrder.add(key);
                _typeLabels[key] = name;
                _pendingExpanded[key] = false;
                _completedExpanded[key] = false;
              });
              setModalState(() {
                editingType = false;
                controller.text = '自定义名称';
              });
            }

            return Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: const Color(0xFFFFFDF6),
                child: SizedBox(
                  width: 340,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFFFEAB1),
                            child: Text(
                              '鸭',
                              style: TextStyle(
                                color: AppTokens.textMain,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '上课鸭',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTokens.textMain,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              children: <Widget>[
                                for (final String key in _typeOrder)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _TodoSidebarCard(
                                      title: _typeTitle(key),
                                      onDelete: () async {
                                        final bool? ok = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('删除待办类型'),
                                              content: Text('确认删除“${_typeTitle(key)}”以及其下所有待办吗？'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('取消'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: const Text('删除'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (ok != true) {
                                          return;
                                        }

                                        await _repository.deleteTodosByTaskType(key);
                                        setState(() {
                                          _typeOrder.remove(key);
                                          _typeLabels.remove(key);
                                          _pendingExpanded.remove(key);
                                          _completedExpanded.remove(key);
                                        });
                                        await _load();
                                      },
                                      onTap: () => Navigator.of(dialogContext).maybePop(),
                                    ),
                                  ),
                                if (editingType)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F2F2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: TextField(
                                            controller: controller,
                                            autofocus: true,
                                            maxLength: 12,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              counterText: '',
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: confirmCreateType,
                                          icon: const Icon(Icons.check_circle, color: AppTokens.duckYellow),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setModalState(() {
                                              editingType = false;
                                              controller.text = '自定义名称';
                                            });
                                          },
                                          icon: const Icon(Icons.cancel, color: AppTokens.duckYellow),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _TodoSidebarCard(
                                    title: '+ 新建类型',
                                    highlighted: true,
                                    onTap: () {
                                      setModalState(() {
                                          // 普通态 -> 激活态，插入“自定义名称 + 勾叉”输入行。
                                        editingType = true;
                                        controller.selection = TextSelection(
                                          baseOffset: 0,
                                          extentOffset: controller.text.length,
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: slide, child: child);
      },
    );

    controller.dispose();
  }

  Future<void> _openSharePlaceholder() async {
    await DuckModal.show<void>(
      context: context,
      child: const DuckModalFrame(
        title: '分享待办',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppTokens.space12),
          child: Text('待办分享能力会在后续任务接入。'),
        ),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.item,
    required this.completed,
    required this.onToggle,
    required this.onDelete,
  });

  final TodoItem item;
  final bool completed;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final DateTime? dueAt = DateTime.tryParse(item.dueAt)?.toLocal();
    final String dueText =
        dueAt == null ? '无截止时间' : DateFormat('M月d日 HH:mm').format(dueAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => onToggle(!item.isCompleted),
            child: Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isCompleted ? AppTokens.duckYellow : const Color(0xFFCDBFA8),
                  width: 1.2,
                ),
                color: item.isCompleted ? AppTokens.duckYellow : Colors.transparent,
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: completed ? const Color(0xFFB2A592) : const Color(0xFF2F271D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueText,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB2A592)),
                ),
                if ((item.courseName ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1DD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.courseName!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5E8A4A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFC6BBA8)),
            onPressed: onDelete,
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _TodoSidebarCard extends StatelessWidget {
  const _TodoSidebarCard({
    required this.title,
    required this.onTap,
    this.highlighted = false,
    this.onDelete,
  });

  final String title;
  final bool highlighted;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFFFFF2C9) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: 76,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: highlighted ? const Color(0xFFB98500) : AppTokens.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  splashRadius: 18,
                  icon: const Icon(
                    Icons.delete,
                    color: AppTokens.duckYellow,
                    size: 20,
                  ),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
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
