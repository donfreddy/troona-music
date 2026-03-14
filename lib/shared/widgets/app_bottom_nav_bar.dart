import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/player/presentation/widgets/rotating_artwork.dart';

/// The five-tab navigation bar shown at the bottom of the shell.
///
/// The centre slot is not a real tab — it renders the current track artwork
/// and opens [FullPlayerPage] on tap.
///
/// **Rebuild strategy**: [BlocBuilder] is gated by [_navKey] so the bar
/// only rebuilds when the current track ID or play/pause state changes.
/// Position/progress events from the audio stream are ignored.
enum AppTab {
  home,
  queue,
  player, // centre artwork slot — opens FullPlayer, not a real tab
  search,
  visualizer,
}

class AppBottomNavBar extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      // Only rebuild when the visible track or play state changes.
      buildWhen: (p, c) => _navKey(p) != _navKey(c),
      builder: (context, playerState) {
        final track = playerState is PlayerActive
            ? playerState.currentTrack
            : null;
        final isPlaying = playerState is PlayerActive && playerState.isPlaying;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: _NavBarBody(
              currentTab: currentTab,
              onTabChanged: onTabChanged,
              track: track,
              isPlaying: isPlaying,
            ),
          ),
        );
      },
    );
  }

  /// Extracts the minimal state that requires a visual rebuild.
  (String?, bool) _navKey(PlayerState s) => switch (s) {
    PlayerActive(:final currentTrack, :final isPlaying) => (
      currentTrack.id,
      isPlaying,
    ),
    _ => (null, false),
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavBarBody extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;
  final Track? track;
  final bool isPlaying;

  const _NavBarBody({
    required this.currentTab,
    required this.onTabChanged,
    required this.track,
    required this.isPlaying,
  });

  static const _tabs = [
    (AppTab.home, CupertinoIcons.house_fill, 'Home'),
    (AppTab.queue, CupertinoIcons.list_bullet, 'Queue'),
    (AppTab.player, null, null), // centre artwork slot
    (AppTab.search, CupertinoIcons.search, 'Search'),
    (AppTab.visualizer, CupertinoIcons.waveform, 'Now'),
  ];

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);
    final radius = BorderRadius.circular(AppSpacing.radiusXl + 4);

    final bar = Container(
      height: 64,
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: radius,
        border: Border.all(color: glass.border, width: glass.borderWidth),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: _tabs.map((tab) {
              final (appTab, icon, label) = tab;
              if (appTab == AppTab.player) {
                return Expanded(
                  child: _CenterArtworkSlot(
                    track: track,
                    isPlaying: isPlaying,
                    onTap: () => context.go(FullPlayerPage.routeName),
                  ),
                );
              }
              return Expanded(
                child: _TabItem(
                  icon: icon!,
                  label: label!,
                  isActive: currentTab == appTab,
                  onTap: () => onTabChanged(appTab),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    if (glass.blurSigma == 0) {
      return ClipRRect(borderRadius: radius, child: bar);
    }

    // RepaintBoundary isolates the BackdropFilter compositing layer so
    // position-stream rebuilds above in the tree do not trigger a re-blur.
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass.blurSigma,
            sigmaY: glass.blurSigma,
            tileMode: TileMode.clamp,
          ),
          child: bar,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Centre slot that renders the rotating artwork and opens the full player.
class _CenterArtworkSlot extends StatelessWidget {
  final Track? track;
  final bool isPlaying;
  final VoidCallback onTap;

  const _CenterArtworkSlot({
    required this.track,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = context.colors.accent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Accent glow ring behind the artwork when playing.
            if (isPlaying)
              Positioned(
                top: -8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: .40),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

            // Rotating artwork disc — elevated 12 px above the bar surface.
            Positioned(
              top: -12,
              child: RotatingArtwork(
                track: track,
                isPlaying: isPlaying,
                size: 56,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use labelPrimary (white on dark, black on light) instead of a hardcoded
    // color so the tab bar remains correct if a light theme is ever enabled.
    final labelColor = context.colors.labelPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isActive ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: labelColor, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
