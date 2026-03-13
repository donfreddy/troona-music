import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';

class AppShell extends StatefulWidget {
  final Widget child; // page courante injectée par GoRouter
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _currentTab = AppTab.home;

  void _onTabChanged(AppTab tab) {
    setState(() => _currentTab = tab);
    // GoRouter branch navigation
    switch (tab) {
      case AppTab.home:
        context.go('/home');
      case AppTab.queue:
        context.go('/queue');
      case AppTab.search:
        context.go('/search');
      case AppTab.visualizer:
        context.go('/visualizer');
      case AppTab.player:
        break; // géré par _CenterArtworkSlot directement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Page courante ────────────────────────────────
          Positioned.fill(child: widget.child),

          // ── BottomNavBar flottante en bas ────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNavBar(currentTab: _currentTab, onTabChanged: _onTabChanged),
          ),
        ],
      ),
    );
  }
}
