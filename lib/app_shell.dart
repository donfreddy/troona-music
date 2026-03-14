import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/features/library/presentation/bloc/library_bloc.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/mini_player.dart';

/// Root scaffold for all shell routes (routes that share the bottom nav bar).
///
/// Stacks the active page, the [MiniPlayer] (when a track is loaded), and the
/// [AppBottomNavBar] from back to front inside a [Stack]. Both the mini-player
/// and its 6 px separator are driven by a single [BlocBuilder] so they
/// appear and disappear atomically.
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
  AppTab _currentTab = AppTab.home;

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
    setState(() => _currentTab = tab);
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
        break; // handled by the center artwork slot in AppBottomNavBar
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Active page ───────────────────────────────────────────────────
          Positioned.fill(child: widget.child),

          // ── MiniPlayer + NavBar ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Both the MiniPlayer and its gap are driven by the same
                // BlocBuilder to ensure they update atomically.
                BlocBuilder<PlayerBloc, PlayerState>(
                  buildWhen: (prev, curr) =>
                      (prev is PlayerActive) != (curr is PlayerActive),
                  builder: (_, state) {
                    final isActive = state is PlayerActive;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: isActive
                              ? const MiniPlayer()
                              : const SizedBox.shrink(),
                        ),
                        if (isActive) const SizedBox(height: 6),
                      ],
                    );
                  },
                ),

                // NavBar is always present.
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, safeBottom + 12),
                  child: AppBottomNavBar(
                    currentTab: _currentTab,
                    onTabChanged: _onTabChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
