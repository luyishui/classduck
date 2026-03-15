import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/duck_modal.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _dailyEnabled = true;
  bool _classEnabled = true;

  int _dailyOffsetDay = 1;
  int _dailyHour = 20;
  int _dailyMinute = 25;

  String _classReminder = '课前 30 分钟';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.pageBackground,
      appBar: AppBar(title: const Text('提醒与通知')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: <Widget>[
          _ReminderCard(
            title: '每日提醒',
            enabled: _dailyEnabled,
            timeText: '前 $_dailyOffsetDay 天 ${_two(_dailyHour)}:${_two(_dailyMinute)}',
            onToggle: (bool value) {
              setState(() {
                _dailyEnabled = value;
              });
            },
            onTapTime: _openDailyWheelModal,
          ),
          const SizedBox(height: 12),
          _ReminderCard(
            title: '课前提醒',
            enabled: _classEnabled,
            timeText: _classReminder,
            onToggle: (bool value) {
              setState(() {
                _classEnabled = value;
              });
            },
            onTapTime: _openClassReminderModal,
          ),
        ],
      ),
    );
  }

  Future<void> _openClassReminderModal() async {
    String selected = _classReminder;

    await DuckModal.show<void>(
      context: context,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setInnerState) {
          return DuckModalFrame(
            title: '设置提醒时间',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _OptionPill(
                  text: '课前 10 分钟',
                  selected: selected == '课前 10 分钟',
                  onTap: () {
                    setInnerState(() {
                      selected = '课前 10 分钟';
                    });
                  },
                ),
                const SizedBox(height: 10),
                _OptionPill(
                  text: '课前 30 分钟',
                  selected: selected == '课前 30 分钟',
                  onTap: () {
                    setInnerState(() {
                      selected = '课前 30 分钟';
                    });
                  },
                ),
                const SizedBox(height: 10),
                _OptionPill(
                  text: '课前 1 小时',
                  selected: selected == '课前 1 小时',
                  onTap: () {
                    setInnerState(() {
                      selected = '课前 1 小时';
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _classReminder = selected;
                      });
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.duckYellow,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确认'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDailyWheelModal() async {
    int offset = _dailyOffsetDay;
    int hour = _dailyHour;
    int minute = _dailyMinute;

    final FixedExtentScrollController hourController =
        FixedExtentScrollController(initialItem: hour);
    final FixedExtentScrollController minuteController =
        FixedExtentScrollController(initialItem: minute);

    await DuckModal.show<void>(
      context: context,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setInnerState) {
          return DuckModalFrame(
            title: '设置提醒时间',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _OptionPill(
                        text: '前 1 天',
                        selected: offset == 1,
                        onTap: () {
                          setInnerState(() {
                            offset = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OptionPill(
                        text: '前 2 天',
                        selected: offset == 2,
                        onTap: () {
                          setInnerState(() {
                            offset = 2;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 132,
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 46,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTokens.duckYellowSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: hourController,
                              itemExtent: 40,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (int value) {
                                setInnerState(() {
                                  hour = value;
                                });
                              },
                              children: List<Widget>.generate(24, (int i) {
                                return Center(
                                  child: Text(
                                    _two(i),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: i == hour ? FontWeight.w700 : FontWeight.w500,
                                      color: i == hour ? AppTokens.textMain : AppTokens.textMuted,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(
                            width: 22,
                            child: Center(
                              child: Text(
                                ':',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: minuteController,
                              itemExtent: 40,
                              selectionOverlay: const SizedBox.shrink(),
                              onSelectedItemChanged: (int value) {
                                setInnerState(() {
                                  minute = value;
                                });
                              },
                              children: List<Widget>.generate(60, (int i) {
                                return Center(
                                  child: Text(
                                    _two(i),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: i == minute ? FontWeight.w700 : FontWeight.w500,
                                      color: i == minute ? AppTokens.textMain : AppTokens.textMuted,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _dailyOffsetDay = offset;
                        _dailyHour = hour;
                        _dailyMinute = minute;
                      });
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.duckYellow,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确认'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _two(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.enabled,
    required this.timeText,
    required this.onToggle,
    required this.onTapTime,
  });

  final String title;
  final bool enabled;
  final String timeText;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTapTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.textMain,
                    ),
                  ),
                ),
                _PillSwitch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1E9DA)),
          InkWell(
            onTap: onTapTime,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: <Widget>[
                  const Text(
                    '提醒时间',
                    style: TextStyle(fontSize: 14, color: AppTokens.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTokens.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFFC6BBA8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillSwitch extends StatelessWidget {
  const _PillSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppTokens.duckYellow : const Color(0xFFE5DED4),
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTokens.duckYellowSoft : const Color(0xFFF8F5EF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: selected ? const Color(0xFFD89B00) : AppTokens.textMain,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
