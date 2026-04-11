import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/player/presentation/widgets/rotating_artwork.dart';
import 'package:troona/shared/widgets/marquee.dart';

import '../../features/player/domain/entities/repeat_mode.dart';

/// Unified bottom bar: an optional mini player row stacked above the five nav
/// tabs inside a single glass container.
///
/// When a track is active the mini player section slides in via [AnimatedSize].
/// Both sections share one [BackdropFilter] / [RepaintBoundary], keeping the
/// screen within the two-filter budget.
///
/// **Rebuild strategy**: [BlocBuilder] is gated by [_navKey] — only the track
/// ID and play/pause flag trigger a rebuild. Position / progress events from
/// the audio stream are ignored.
enum AppTab {
  home,
  library,
  player, // centre artwork slot — opens FullPlayer, not a real tab
  search,
  playlists,
}

class AppBottomNavBar extends StatefulWidget {
  // static const double miniPlayerRowHeight = 64;
  // static const double navRowHeight = 64;
  // static const double activeHeight = miniPlayerRowHeight + navRowHeight;
  // static const double floatingMargin = 12;

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;

  /// Whether to show the embedded mini player row above the nav tabs.
  /// Set to false in [FullPlayerPage] where the full player UI already
  /// covers that role.
  final bool showMiniPlayer;

  /// Whether to show the navigation tabs.
  /// Set to false on sub-pages (detail pages) where only the mini player
  /// should remain visible.
  final bool showTabs;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.showMiniPlayer = true,
    this.showTabs = true,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  PlayerActive? _lastActiveState;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final resolvedPlayerState = _resolvePlayerState(playerState);
        return _NavBarBody(
          currentTab: widget.currentTab,
          onTabChanged: widget.onTabChanged,
          playerState: resolvedPlayerState,
          showMiniPlayer: widget.showMiniPlayer,
          showTabs: widget.showTabs,
        );
      },
    );
  }

  // (String?, bool) _navKey(PlayerState s) => switch (s) {
  //   PlayerActive(:final currentTrack, :final isPlaying) => (
  //     currentTrack.id,
  //     isPlaying,
  //   ),
  //   PlayerLoading(:final track) => (track.id, true),
  //   _ => (null, false),
  // };

  PlayerActive? _resolvePlayerState(PlayerState state) {
    if (state is PlayerActive) {
      _lastActiveState = state;
      return state;
    }
    if (state is PlayerLoading) {
      // Si on charge, on garde l'ancien état mais on met à jour le titre/pochette
      final previous = _lastActiveState;
      final next = PlayerActive(
        currentTrack: state.track,
        status: PlaybackStatus.paused,
        position: Duration.zero,
        buffered: Duration.zero,
        duration: Duration(milliseconds: state.track.durationMs),
        queue: previous?.queue ?? Queue.single(state.track),
        shuffleEnabled: previous?.shuffleEnabled ?? false,
        repeatMode: previous?.repeatMode ?? RepeatMode.off,
      );
      _lastActiveState = next;
      return next;
    }
    if (state is PlayerIdle) {
      _lastActiveState = null;
      return null;
    }
    // Pour PlayerError, on garde le dernier état valide pour ne pas faire disparaître le player
    return _lastActiveState;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NavBarBody extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;

  /// Non-null when a track is active; drives the mini player row visibility.
  final PlayerActive? playerState;
  final bool showMiniPlayer;
  final bool showTabs;

  const _NavBarBody({
    required this.currentTab,
    required this.onTabChanged,
    required this.playerState,
    required this.showMiniPlayer,
    required this.showTabs,
  });

  static const _tabs = [
    (AppTab.home, LucideIcons.house, 'Home'),
    (AppTab.library, LucideIcons.library, 'Library'),
    (AppTab.player, null, null), // centre artwork slot
    (AppTab.search, LucideIcons.search, 'Search'),
    (AppTab.playlists, LucideIcons.listMusic, 'Playlists'),
  ];

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.card(context);
    final radius = BorderRadius.circular(AppSpacing.radiusXl + 4);
    final isMiniPlayerVisible = showMiniPlayer && playerState != null;

    if (!isMiniPlayerVisible && !showTabs) return const SizedBox.shrink();

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
            child: isMiniPlayerVisible
                ? _MiniPlayerRow(
                    state: playerState!,
                    radius: radius,
                    showTabs: showTabs,
                  )
                : const SizedBox.shrink(),
          ),

          // ── Nav tabs row — visible only on root pages ────────────────────
          if (showTabs)
            SizedBox(
              height: AppSpacing.navBarHeight,
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
class _MiniPlayerRow extends StatelessWidget {
  final PlayerActive state;
  final BorderRadius radius;
  final bool showTabs;

  const _MiniPlayerRow({
    required this.state,
    required this.radius,
    this.showTabs = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glass = GlassTheme.miniPlayer(context);

    return Dismissible(
      key: ValueKey(state.currentTrack.id),
      direction: DismissDirection.down,
      onDismissed: (_) {
        context.read<PlayerBloc>().add(const PlayerDismissed());
      },
      child: GestureDetector(
        onTap: () => _openFullPlayer(context),
        onVerticalDragEnd: (d) {
          // Swipe up with sufficient velocity → open full player.
          if (d.velocity.pixelsPerSecond.dy < -300) {
            _openFullPlayer(context);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: AppSpacing.miniPlayerHeight,
          decoration: showTabs
              ? BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    width: showTabs ? 0 : 1,
                    color: glass.border,
                  ),
                )
              : null,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (showTabs)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x1FFFFFFF), Color(0x0AFFFFFF)],
                      ),
                    ),
                  ),
                _MiniPlayerProgressFill(progressTint: glass.border),
                Row(
                  children: [
                    const SizedBox(width: 12),

                    // ── Artwork thumbnail ────────────────────────
                    SizedBox.square(
                      dimension: 42,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: state.currentTrack.artworkPath != null
                            ? Image.file(
                                File(state.currentTrack.artworkPath!),
                                fit: BoxFit.cover,
                              )
                            : ColoredBox(
                                color: colors.glassFill,
                                child: Icon(
                                  LucideIcons.music,
                                  color: colors.labelTertiary,
                                  size: 18,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Track title and artist ─────────────────────────────
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Marquee(
                            text: state.currentTrack.title,
                            style: TextStyle(
                              color: colors.labelPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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

                    // ── Play / Pause ───────────────────────────────────────
                    IconButton(
                      onPressed: () => context.read<PlayerBloc>().add(
                        state.isPlaying
                            ? const PauseRequested()
                            : const ResumeRequested(),
                      ),
                      icon: Icon(
                        state.isPlaying ? LucideIcons.pause : LucideIcons.play,
                      ),
                    ),

                    // ── Skip next ──────────────────────────────────────────
                    IconButton(
                      onPressed: () => context.read<PlayerBloc>().add(
                        const SkipNextRequested(),
                      ),
                      icon: Icon(LucideIcons.skipForward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerProgressFill extends StatelessWidget {
  final Color progressTint;

  const _MiniPlayerProgressFill({required this.progressTint});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlayerBloc, PlayerState, double>(
      selector: (state) => switch (state) {
        PlayerActive(:final progressRatio) => progressRatio.clamp(0.0, 1.0),
        _ => 0.0,
      },
      builder: (context, progress) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: progress),
          duration: const Duration(milliseconds: 220),
          curve: Curves.linear,
          builder: (context, animatedProgress, _) {
            if (animatedProgress <= 0) return const SizedBox.shrink();

            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animatedProgress <= 0 ? 0.02 : animatedProgress,
                heightFactor: 1,
                child: ColoredBox(
                  color: progressTint,
                  // decoration: BoxDecoration(
                  //   gradient: LinearGradient(
                  //     begin: Alignment.centerLeft,
                  //     end: Alignment.centerRight,
                  //     colors: [
                  //       // progressTint.withValues(alpha: .42),
                  //       // progressTint.withValues(alpha: .28),
                  //       progressTint.withValues(alpha: .14),
                  //     ],
                  //   ),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: progressTint.withValues(alpha: .18),
                  //     blurRadius: 18,
                  //     spreadRadius: 2,
                  //   ),
                  // ],
                  //),
                  child: const SizedBox.expand(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void _openFullPlayer(BuildContext context) {
  if (GoRouterState.of(context).matchedLocation == FullPlayerPage.routeName) {
    return;
  }
  getIt<PlaybackSessionStore>().setFullPlayerOpen(true);
  context.push(FullPlayerPage.routeName);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Centre slot that renders the rotating artwork disc and opens the full player.
class _CenterArtworkSlot extends StatelessWidget {
  final Track? track;
  final bool isPlaying;

  const _CenterArtworkSlot({required this.track, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    // final accentColor = context.colors.accent;

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Accent glow ring behind the artwork when playing.
          // if (isPlaying)
          //   Positioned(
          //     top: -8,
          //     child: AnimatedContainer(
          //       duration: const Duration(milliseconds: 400),
          //       width: 66,
          //       height: 66,
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         boxShadow: [BoxShadow(color: accentColor.withValues(alpha: .40), blurRadius: 24, spreadRadius: 4)],
          //       ),
          //     ),
          //   ),

          // Rotating artwork disc — elevated 12 px above the bar surface.
          Positioned(
            child: RotatingArtwork(track: null, isPlaying: isPlaying, size: 56),
          ),
        ],
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
              Icon(icon, color: labelColor, size: 24),
              // const SizedBox(height: 3),
              // Text(
              //   label,
              //   style: TextStyle(
              //     color: labelColor,
              //     fontSize: 10,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
