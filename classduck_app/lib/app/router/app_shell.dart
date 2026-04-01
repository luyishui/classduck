import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/profile/ui/profile_page.dart';
import '../../features/schedule/ui/schedule_page.dart';
import '../../features/todo/ui/todo_page.dart';
import '../../shared/theme/app_motion.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/widgets/duck_pressable.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;

  final List<Widget> _pages = const <Widget>[
    SchedulePage(),
    TodoPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const double navHeight = 74;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: IndexedStack(index: _tabIndex, children: _pages),
          ),
          Positioned(
            left: 28,
            right: 28,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: navHeight,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTokens.surface.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1F2E2011),
                        blurRadius: 30,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final double itemWidth =
                              constraints.maxWidth / _pages.length;
                          const double indicatorInset = 4;

                          return Stack(
                            children: <Widget>[
                              AnimatedPositioned(
                                duration: AppMotion.regular,
                                curve: AppMotion.decelerate,
                                left: itemWidth * _tabIndex + indicatorInset,
                                top: indicatorInset,
                                width: itemWidth - indicatorInset * 2,
                                height:
                                    constraints.maxHeight - indicatorInset * 2,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFFFFF7D7),
                                        Color(0xFFFFECAD),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: const <BoxShadow>[
                                      BoxShadow(
                                        color: Color(0x26D19B00),
                                        blurRadius: 18,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _NavItem(
                                      active: _tabIndex == 0,
                                      icon: Icons.calendar_today_outlined,
                                      activeIcon: Icons.calendar_today,
                                      label: '课表',
                                      onTap: () => _onTapTab(0),
                                    ),
                                  ),
                                  Expanded(
                                    child: _NavItem(
                                      active: _tabIndex == 1,
                                      icon: Icons.fact_check_outlined,
                                      activeIcon: Icons.fact_check,
                                      label: '待办',
                                      onTap: () => _onTapTab(1),
                                    ),
                                  ),
                                  Expanded(
                                    child: _NavItem(
                                      active: _tabIndex == 2,
                                      icon: Icons.person_outline,
                                      activeIcon: Icons.person,
                                      label: '我的',
                                      onTap: () => _onTapTab(2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTapTab(int index) {
    if (_tabIndex == index) {
      return;
    }
    setState(() {
      _tabIndex = index;
    });
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.active,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DuckPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      pressedScale: 0.985,
      hoverScale: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: AnimatedSlide(
          duration: AppMotion.quick,
          curve: AppMotion.emphasized,
          offset: active ? Offset.zero : const Offset(0, 0.04),
          child: AnimatedOpacity(
            duration: AppMotion.quick,
            curve: AppMotion.standard,
            opacity: active ? 1 : 0.78,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: AppMotion.quick,
                    switchInCurve: AppMotion.decelerate,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                    child: Icon(
                      active ? activeIcon : icon,
                      key: ValueKey<bool>(active),
                      size: 18,
                      color: active
                          ? const Color(0xFFD19B00)
                          : const Color(0xFF8A7C6C),
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: AppMotion.quick,
                    curve: AppMotion.standard,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active
                          ? const Color(0xFFD19B00)
                          : const Color(0xFF8A7C6C),
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
