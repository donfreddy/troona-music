import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/features/player/presentation/bloc/player_bloc.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/mini_player.dart';

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
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Page courante ────────────────────────────────
          Positioned.fill(child: widget.child),

          // ── Bloc bas : MiniPlayer + NavBar dans UN seul Positioned ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // MiniPlayer — visible seulement si un track est actif
                // ET qu'on n'est PAS sur le FullPlayer
                BlocBuilder<PlayerBloc, PlayerState>(
                  buildWhen: (p, c) =>
                      (p is PlayerActive) != (c is PlayerActive),
                  builder: (_, state) => AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: _showMiniPlayer
                        ? const MiniPlayer()
                        : const SizedBox.shrink(),
                  ),
                ),

                // 6px de séparation entre les deux cartes
                if (_showMiniPlayer) const SizedBox(height: 6),

                // NavBar — toujours présente
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

  // FullPlayer est une route modale hors du ShellRoute
  // donc _showMiniPlayer = true sur toutes les pages du shell
  bool get _showMiniPlayer {
    final state = context.read<PlayerBloc>().state;
    return state is PlayerActive;
  }
}
