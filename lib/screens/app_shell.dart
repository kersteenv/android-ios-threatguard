import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/aurora_background.dart';
import '../widgets/floating_dock.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'sms_monitor_screen.dart';
import 'threat_center_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _items = [
    DockItem(Icons.dashboard_rounded, 'Dashboard'),
    DockItem(Icons.sms_rounded, 'Monitor'),
    DockItem(Icons.shield_rounded, 'Threats'),
    DockItem(Icons.insights_rounded, 'Reports'),
    DockItem(Icons.tune_rounded, 'Settings'),
  ];

  void _go(int i) => setState(() => _index = i);

  Widget _page() => switch (_index) {
    0 => DashboardScreen(onNavigate: _go),
    1 => const SmsMonitorScreen(),
    2 => const ThreatCenterScreen(),
    3 => const ReportsScreen(),
    _ => const SettingsScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: Material(
          type: MaterialType.transparency,
          textStyle: AppTheme.baseText,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_index),
                        child: _page(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FloatingDock(
                      items: _items,
                      index: _index,
                      onChanged: _go,
                    ),
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
