import 'package:flutter/material.dart';

import '../../features/profile/ui/profile_page.dart';
import '../../features/schedule/ui/schedule_page.dart';
import '../../features/todo/ui/todo_page.dart';
import '../../shared/theme/app_tokens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 1;
  final Set<int> _loadedTabs = <int>{1};

  List<Widget> _buildPages() {
    return <Widget>[
      _loadedTabs.contains(0) ? const TodoPage() : const SizedBox.shrink(),
      _loadedTabs.contains(1) ? const SchedulePage() : const SizedBox.shrink(),
      _loadedTabs.contains(2) ? const ProfilePage() : const SizedBox.shrink(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const double navHeight = 64;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          IndexedStack(index: _tabIndex, children: _buildPages()),
          Positioned(
            left: 28,
            right: 28,
            bottom: 20,
            child: Container(
              height: navHeight,
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1F2E2011),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _NavItem(
                      active: _tabIndex == 0,
                      icon: Icons.fact_check_outlined,
                      activeIcon: Icons.fact_check,
                      label: '待办',
                      onTap: () => _onTapTab(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      active: _tabIndex == 1,
                      icon: Icons.calendar_today_outlined,
                      activeIcon: Icons.calendar_today,
                      label: '课表',
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
      _loadedTabs.add(index);
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
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(active ? activeIcon : icon, size: 18),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFF2CC) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                color: active
                    ? const Color(0xFFD19B00)
                    : const Color(0xFF8A7C6C),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: active
                      ? const Color(0xFFD19B00)
                      : const Color(0xFF8A7C6C),
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
