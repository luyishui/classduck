import 'package:flutter/material.dart';
import 'package:lpinyin/lpinyin.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/widgets/duck_pressable.dart';
import '../../../shared/navigation/duck_page_route.dart';
import '../data/school_config_repository.dart';
import '../domain/school_config.dart';
import 'import_execution_page.dart';

class ImportSchoolListPage extends StatefulWidget {
  const ImportSchoolListPage({super.key});

  @override
  State<ImportSchoolListPage> createState() => _ImportSchoolListPageState();
}

class _ImportSchoolListPageState extends State<ImportSchoolListPage> {
  final SchoolConfigRepository _repository = SchoolConfigRepository();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _schoolLevelTabs = <String>[
    '本/专科',
    '硕士',
    '通用',
  ];

  static const List<String> _schoolLevelKeys = <String>[
    'undergraduate',
    'master',
    'general',
  ];

  bool _loading = false;
  String? _error;
  bool _searchActive = false;
  String _keyword = '';
  String _activeLetter = '#';
  int _activeLevelIndex = 0;
  Map<String, double> _letterOffsets = <String, double>{};
  List<String> _orderedLetters = const <String>[];

  List<SchoolConfig> _allConfigs = const <SchoolConfig>[];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<SchoolConfig> data = await _repository.fetchSchoolConfigs();
      data.sort((SchoolConfig a, SchoolConfig b) => a.title.compareTo(b.title));
      setState(() {
        _allConfigs = data;
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
    // 数据过滤顺序：先关键字过滤，再按首字母分组渲染。
    final List<SchoolConfig> filtered = _filteredConfigs();
    final Map<String, List<SchoolConfig>> grouped = _groupByLetter(filtered);
    final List<String> letters = grouped.keys.toList(growable: false);
    _orderedLetters = letters;
    _letterOffsets = _computeLetterOffsets(grouped);
    final String effectiveActiveLetter = letters.isEmpty
      ? '#'
      : (letters.contains(_activeLetter) ? _activeLetter : letters.first);

    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTokens.pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTokens.textMain,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AnimatedSwitcher(
          duration: AppMotion.quick,
          child: _searchActive
              ? Container(
                  key: const ValueKey<String>('search'),
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTokens.radius20),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (String value) {
                      setState(() {
                        _keyword = value.trim();
                      });
                    },
                    style: const TextStyle(fontSize: 15, color: AppTokens.textMain),
                    decoration: InputDecoration(
                      hintText: '搜索学校名称…',
                      hintStyle: TextStyle(color: AppTokens.textMuted.withAlpha(160)),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppTokens.textMuted.withAlpha(160)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                )
              : const Text(
                  key: ValueKey<String>('title'),
                  '选择学校',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textMain,
                  ),
                ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              _searchActive ? Icons.close_rounded : Icons.search_rounded,
              size: 22,
            ),
            color: AppTokens.textMain,
            onPressed: () {
              setState(() {
                _searchActive = !_searchActive;
                if (!_searchActive) {
                  _searchController.clear();
                  _keyword = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: GestureDetector(
              onHorizontalDragEnd: (DragEndDetails details) {
                // 交互要求：分栏支持左右滑动切换，不仅限于点击。
                final double velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 120) {
                  return;
                }
                setState(() {
                  if (velocity < 0 && _activeLevelIndex < _schoolLevelTabs.length - 1) {
                    _activeLevelIndex++;
                  } else if (velocity > 0 && _activeLevelIndex > 0) {
                    _activeLevelIndex--;
                  }
                });
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < _schoolLevelTabs.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == _schoolLevelTabs.length - 1 ? 0 : 4),
                          child: _SchoolLevelTab(
                            label: _schoolLevelTabs[i],
                            active: _activeLevelIndex == i,
                            onTap: () {
                              setState(() {
                                _activeLevelIndex = i;
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '💡 找不到学校？试试搜索或使用「通用教务」',
                style: TextStyle(fontSize: 12, color: AppTokens.textMuted),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTokens.duckYellow, strokeWidth: 3))
                : _error != null
                    ? _buildError()
                    : filtered.isEmpty
                        ? const Center(child: Text('未找到该学校'))
                        : Stack(
                            children: <Widget>[
                              NotificationListener<ScrollNotification>(
                                onNotification: (ScrollNotification notification) {
                                  _onScroll();
                                  return false;
                                },
                                child: ListView(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(20, 4, 44, 100),
                                  children: _buildGroupedList(grouped),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                bottom: 24,
                                child: _LetterBar(
                                  letters: letters,
                                  activeLetter: effectiveActiveLetter,
                                  onTapLetter: (String letter) {
                                    _jumpToLetter(letter, grouped);
                                  },
                                ),
                              ),
                              Positioned(
                                right: 20,
                                bottom: 108,
                                child: Column(
                                  children: <Widget>[
                                    _ToolButton(
                                      icon: Icons.download,
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('请先点击学校后进入导入流程。')),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _ToolButton(
                                      icon: Icons.question_mark,
                                      onTap: () {
                                        _showHelp();
                                      },
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('😢', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '加载失败',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.textMain),
          ),
          const SizedBox(height: 4),
          Text(
            '$_error',
            style: const TextStyle(fontSize: 13, color: AppTokens.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          DuckPressable(
            borderRadius: BorderRadius.circular(AppTokens.radius20),
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTokens.duckYellow,
                borderRadius: BorderRadius.circular(AppTokens.radius20),
              ),
              child: const Text('重试', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedList(Map<String, List<SchoolConfig>> grouped) {
    final List<Widget> widgets = <Widget>[];

    grouped.forEach((String letter, List<SchoolConfig> schools) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTokens.duckYellowSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.duckYellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: AppTokens.duckYellowSoft),
              ),
            ],
          ),
        ),
      );

      for (final SchoolConfig config in schools) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DuckPressable(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openExecutionPage(config),
              child: GestureDetector(
                onLongPress: () => _showConfigPreview(config),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTokens.duckYellowSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('\ud83c\udfeb', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          config.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.textMain,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 20, color: AppTokens.textMuted.withAlpha(120)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    });

    return widgets;
  }

  List<SchoolConfig> _filteredConfigs() {
    // 搜索行为：有关键字时跨所有分栏搜索（模糊匹配校名和 id）；
    // 无关键字时按当前分栏层级过滤。
    final String keyword = _keyword.trim().toLowerCase();

    if (keyword.isNotEmpty) {
      return _allConfigs.where((SchoolConfig config) {
        return config.title.toLowerCase().contains(keyword) ||
            config.id.toLowerCase().contains(keyword);
      }).toList(growable: false);
    }

    final String activeLevel = _schoolLevelKeys[_activeLevelIndex];
    return _allConfigs
        .where((SchoolConfig config) => config.level == activeLevel)
        .toList(growable: false);
  }

  Map<String, List<SchoolConfig>> _groupByLetter(List<SchoolConfig> configs) {
    // 分组策略：A-Z + #，并将无法归类项统一归到 #。
    final Map<String, List<SchoolConfig>> grouped = <String, List<SchoolConfig>>{};

    for (final SchoolConfig config in configs) {
      final String letter = _initialLetter(config.title);
      grouped.putIfAbsent(letter, () => <SchoolConfig>[]).add(config);
    }

    final List<String> keys = grouped.keys.toList()..sort();
    if (keys.remove('#')) {
      keys.add('#');
    }

    return <String, List<SchoolConfig>>{
      for (final String key in keys) key: grouped[key]!,
    };
  }

  String _initialLetter(String text) {
    if (text.isEmpty) {
      return '#';
    }

    // 中文学校名按拼音首字母分组，保证本/专科和硕士分栏也可走 A-Z 导航。
    final String pinyin = PinyinHelper.getPinyinE(text, defPinyin: '#', separator: '');
    final String c = (pinyin.isNotEmpty ? pinyin.substring(0, 1) : '#').toUpperCase();
    final RegExp az = RegExp(r'^[A-Z]$');
    if (az.hasMatch(c)) {
      return c;
    }
    return '#';
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_orderedLetters.isEmpty || _letterOffsets.isEmpty) {
      return;
    }

    final double offset = _scrollController.offset;
    String letter = _orderedLetters.first;
    for (int i = 0; i < _orderedLetters.length; i++) {
      final String current = _orderedLetters[i];
      final double currentOffset = _letterOffsets[current] ?? 0;
      final String? next = i + 1 < _orderedLetters.length ? _orderedLetters[i + 1] : null;
      final double nextOffset = next == null ? double.infinity : (_letterOffsets[next] ?? double.infinity);
      if (offset >= currentOffset && offset < nextOffset) {
        letter = current;
        break;
      }
    }

    if (_activeLetter != letter) {
      setState(() {
        _activeLetter = letter;
      });
    }
  }

  Map<String, double> _computeLetterOffsets(Map<String, List<SchoolConfig>> grouped) {
    double offset = 0;
    final Map<String, double> result = <String, double>{};
    grouped.forEach((String letter, List<SchoolConfig> schools) {
      result[letter] = offset;
      offset += 28;
      offset += schools.length * 74;
    });
    return result;
  }

  void _jumpToLetter(String letter, Map<String, List<SchoolConfig>> grouped) {
    if (!grouped.containsKey(letter)) {
      return;
    }

    // 这里使用估算高度滚动到分组附近，后续可替换为精确锚点映射。
    double offset = 0;
    grouped.forEach((String key, List<SchoolConfig> value) {
      if (key == letter) {
        return;
      }
      offset += 28;
      offset += value.length * 74;
    });

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );

    setState(() {
      _activeLetter = letter;
    });
  }

  Future<void> _showConfigPreview(SchoolConfig config) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(config.title),
          content: SingleChildScrollView(
            child: Text(
              'schoolId: ${config.id}\n'
              'initialUrl: ${config.initialUrl}\n'
              'targetUrl: ${config.targetUrl}\n'
              'script: ${config.extractScriptUrl}',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openExecutionPage(SchoolConfig config) async {
    // 保护：未适配学校（example.com 占位 URL）给出友好提示
    if (config.initialUrl.contains('example.com') || config.initialUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${config.title} 暂未适配教务系统，敬请期待')),
      );
      return;
    }

    final bool? imported = await Navigator.of(context).push<bool>(
      DuckPageRoute<bool>(
        builder: (BuildContext context) => ImportExecutionPage(config: config),
      ),
    );

    if (imported == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radius24)),
          backgroundColor: Colors.white,
          title: const Row(
            children: <Widget>[
              Text('📖', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text('导入帮助', style: TextStyle(fontWeight: FontWeight.w700, color: AppTokens.textMain)),
            ],
          ),
          content: const Text(
            '1. 先选择你的学校\n2. 进入教务系统登录\n3. 进入课表页后点击导入',
            style: TextStyle(fontSize: 14, color: AppTokens.textMain, height: 1.6),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('我知道啦', style: TextStyle(color: AppTokens.duckYellow, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

class _LetterBar extends StatelessWidget {
  const _LetterBar({
    required this.letters,
    required this.activeLetter,
    required this.onTapLetter,
  });

  final List<String> letters;
  final String activeLetter;
  final ValueChanged<String> onTapLetter;

  @override
  Widget build(BuildContext context) {
    if (letters.isEmpty) {
      return const SizedBox.shrink();
    }

    const double itemExtent = 20;

    void selectByDy(double dy) {
      final int index = (dy ~/ itemExtent).clamp(0, letters.length - 1).toInt();
      onTapLetter(letters[index]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (DragStartDetails details) => selectByDy(details.localPosition.dy - 4),
        onVerticalDragUpdate: (DragUpdateDetails details) => selectByDy(details.localPosition.dy - 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: letters.map((String letter) {
            final bool active = letter == activeLetter;
            return GestureDetector(
              onTap: () => onTapLetter(letter),
              child: AnimatedContainer(
                duration: AppMotion.quick,
                width: 22,
                height: itemExtent,
                margin: const EdgeInsets.symmetric(vertical: 0.5),
                decoration: BoxDecoration(
                  color: active ? AppTokens.duckYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 9,
                      color: active ? Colors.white : AppTokens.textMuted,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuckPressable(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTokens.duckYellow,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTokens.duckYellow.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 24, color: Colors.white),
      ),
    );
  }
}

class _SchoolLevelTab extends StatelessWidget {
  const _SchoolLevelTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        curve: AppMotion.standard,
        width: double.infinity,
        height: 36,
        decoration: BoxDecoration(
          color: active ? AppTokens.duckYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppTokens.duckYellow.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.quick,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : AppTokens.textMuted,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
