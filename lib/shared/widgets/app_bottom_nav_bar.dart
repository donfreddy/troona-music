import 'dart:io';
import 'dart:ui';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/player/presentation/widgets/rotating_artwork.dart';

/// Unified bottom bar: an optional mini player row stacked above the five nav
/// tabs inside a single glass container.
///
/// When a track is active the mini player section slides in via [AnimatedSize].
/// Both sections share one [BackdropFilter] / [RepaintBoundary], keeping the
/// screen within the two-filter budget.
///
/// **Hero transition**: the artwork thumbnail carries the tag
/// `'artwork_<trackId>'` which matches [ArtworkCarousel] in [FullPlayerPage],
/// producing a smooth expanding-circle animation when the full player opens.
///
/// **Rebuild strategy**: [BlocBuilder] is gated by [_navKey] — only the track
/// ID and play/pause flag trigger a rebuild. Position / progress events from
/// the audio stream are ignored.
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

  /// Whether to show the embedded mini player row above the nav tabs.
  /// Set to false in [FullPlayerPage] where the full player UI already
  /// covers that role.
  final bool showMiniPlayer;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.showMiniPlayer = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (p, c) => _navKey(p) != _navKey(c),
      builder: (context, playerState) {
        return _NavBarBody(
          currentTab: currentTab,
          onTabChanged: onTabChanged,
          playerState: (showMiniPlayer && playerState is PlayerActive)
              ? playerState
              : null,
        );
      },
    );
  }

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

  /// Non-null when a track is active; drives the mini player row visibility.
  final PlayerActive? playerState;

  const _NavBarBody({
    required this.currentTab,
    required this.onTabChanged,
    required this.playerState,
  });

  static const _tabs = [
    (AppTab.home, EvaIcons.home, 'Home'),
    (AppTab.queue, EvaIcons.list, 'Queue'),
    (AppTab.player, null, null), // centre artwork slot
    (AppTab.search, EvaIcons.search, 'Search'),
    (AppTab.visualizer, EvaIcons.activity, 'Now'),
  ];

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);
    final radius = BorderRadius.circular(AppSpacing.radiusXl + 4);
    final isActive = playerState != null;

    final body = Container(
      decoration: BoxDecoration(
        color: glass.fill,
        borderRadius: radius,
        border: Border.all(color: glass.border, width: glass.borderWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Mini player section — slides in/out smoothly ─────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: isActive
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniPlayerRow(state: playerState!),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Container(
                          height: 0.5,
                          color: glass.border.withValues(alpha: .6),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Nav tabs row — always present ────────────────────────────────
          SizedBox(
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: _tabs.map((tab) {
                    final (appTab, icon, label) = tab;
                    if (appTab == AppTab.player) {
                      return Expanded(
                        child: _CenterArtworkSlot(
                          track: playerState?.currentTrack,
                          isPlaying: playerState?.isPlaying ?? false,
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
          ),
        ],
      ),
    );

    if (glass.blurSigma == 0) {
      return ClipRRect(borderRadius: radius, child: body);
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
          child: body,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Mini player row embedded at the top of the glass container.
///
/// Tapping anywhere navigates to [FullPlayerPage]. The [CupertinoButton]
/// play/pause and skip controls intercept their own taps so they do not
/// trigger the surrounding [GestureDetector].
///
/// The [Hero] tag `'artwork_<trackId>'` matches [ArtworkCarousel] so the
/// artwork expands from the 38 px thumbnail to the full carousel disc when
/// the full player opens (and contracts back on dismiss).
class _MiniPlayerRow extends StatelessWidget {
  final PlayerActive state;

  const _MiniPlayerRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => context.go(FullPlayerPage.routeName),
      onVerticalDragEnd: (d) {
        // Swipe up with sufficient velocity → open full player.
        if (d.velocity.pixelsPerSecond.dy < -300) {
          context.go(FullPlayerPage.routeName);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            const SizedBox(width: 12),

            // ── Artwork thumbnail with Hero ──────────────────────────────────
            Hero(
              tag: 'artwork_${state.currentTrack.id}',
              child: SizedBox.square(
                dimension: 38,
                child: ClipOval(
                  child: state.currentTrack.artworkPath != null
                      ? Image.file(
                          File(state.currentTrack.artworkPath!),
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: colors.glassFill,
                          child: Icon(
                            EvaIcons.music,
                            color: colors.labelTertiary,
                            size: 18,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ── Track title and artist ───────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.currentTrack.title,
                    style: TextStyle(
                      color: colors.labelPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    state.currentTrack.artist,
                    style: TextStyle(
                      color: colors.labelSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Play / Pause ─────────────────────────────────────────────────
            CupertinoButton(
              padding: const EdgeInsets.all(10),
              onPressed: () => context.read<PlayerBloc>().add(
                state.isPlaying
                    ? const PauseRequested()
                    : const ResumeRequested(),
              ),
              child: Icon(
                state.isPlaying
                    ? EvaIcons.pauseCircle
                    : EvaIcons.playCircle,
                color: colors.labelPrimary,
                size: 20,
              ),
            ),

            // ── Skip next ────────────────────────────────────────────────────
            CupertinoButton(
              padding: const EdgeInsets.only(right: 12),
              onPressed: () =>
                  context.read<PlayerBloc>().add(const SkipNextRequested()),
              child: Icon(
                EvaIcons.arrowForward,
                color: colors.labelPrimary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Centre slot that renders the rotating artwork disc and opens the full player.
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
