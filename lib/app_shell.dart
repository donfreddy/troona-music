import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';

/// Root scaffold for all shell routes (routes that share the bottom nav bar).
///
/// The [AppBottomNavBar] is positioned at the bottom and internally manages
/// both the mini player row (when a track is active) and the nav tabs — as a
/// single unified glass container.
///
/// The initial library scan is dispatched here in [State.initState] via
/// `addPostFrameCallback`. This keeps `app_router.dart` free of
/// business-logic triggers.
class AppShell extends StatefulWidget {
  /// The currently active page injected by GoRouter's [ShellRoute].
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Dispatch the scan after the first frame so that BlocProvider ancestors
    // are fully wired before context.read is called.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryBloc>().add(const LibraryScanRequested());
    });
  }

  void _onTabChanged(AppTab tab) {
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
        break; // handled by the centre artwork slot in AppBottomNavBar
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final currentTab = _tabForLocation(
      GoRouterState.of(context).matchedLocation,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Active page ───────────────────────────────────────────────────
          Positioned.fill(child: widget.child),

          // ── Unified bottom bar (mini player + nav tabs) ───────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, safeBottom + 12),
              child: AppBottomNavBar(
                currentTab: currentTab,
                onTabChanged: _onTabChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppTab _tabForLocation(String location) {
    if (location == '/queue') return AppTab.queue;
    if (location == '/search') return AppTab.search;
    if (location == '/visualizer') return AppTab.visualizer;
    return AppTab.home;
  }
}
