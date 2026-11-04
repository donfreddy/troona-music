import 'dart:io';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/shared/widgets/app_toast.dart';
import 'package:troona/features/player/presentation/pages/full_player_page.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/features/player/presentation/widgets/rotating_artwork.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/artwork_image.dart';
import 'package:troona/shared/widgets/marquee.dart';
import 'package:troona/shared/widgets/toast_anchor.dart';
import 'package:troona/core/theme/components/glass_filter.dart';

import '../../features/player/domain/entities/repeat_mode.dart';
import 'package:troona/shared/widgets/swipe_actions.dart';
import 'package:troona/features/player/presentation/utils/open_full_player.dart';

/// Unified bottom bar: an optional mini player row stacked above the five nav
/// tabs inside a single glass container.
///
/// When a track is active the mini player section slides in via [AnimatedSize].
/// Both sections share one [BackdropFilter] / [RepaintBoundary], keeping the
/// screen within the two-filter budget.
///
/// **Rebuild strategy**: [BlocBuilder] is gated by [_navKey]: only the track
/// ID and play/pause flag trigger a rebuild. Position / progress events from
/// the audio stream are ignored.
enum AppTab {
  home,
  library,
  player, // centre artwork slot: opens FullPlayer, not a real tab
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
    // Toasts sit just above whatever the bar shows, down to nothing.
    // Fixed heights: the font size is followed up to the layout cap.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppLayout.maxTextScale,
      child: ToastAnchor(
        child: BlocBuilder<PlayerBloc, PlayerState>(
          buildWhen: (prev, curr) => _navKey(prev) != _navKey(curr),
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
        ),
      ),
    );
  }

  /// Only what the bar renders: position and buffering ticks are ignored.
  /// The progress fill listens on its own to [PlayerBloc.progress].
  Object? _navKey(PlayerState s) => switch (s) {
    PlayerActive(:final currentTrack, :final isPlaying, :final hasNext) => (
      PlayerActive,
      currentTrack.id,
      isPlaying,
      hasNext,
    ),
    PlayerLoading(:final track) => (PlayerLoading, track.id),
    _ => s.runtimeType,
  };

  PlayerActive? _resolvePlayerState(PlayerState state) {
    if (state is PlayerActive) {
      _lastActiveState = state;
      return state;
    }
    if (state is PlayerLoading) {
      // While loading, keep the previous state but show the new title and cover
      final previous = _lastActiveState;
      final next = PlayerActive(
        currentTrack: state.track,
        status: PlaybackStatus.paused,
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
    // On PlayerError the last valid state is kept so the mini player does not vanish
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
    (AppTab.home, AppIcons.home),
    (AppTab.library, AppIcons.library),
    (AppTab.player, null), // centre artwork slot
    (AppTab.search, AppIcons.search),
    (AppTab.playlists, AppIcons.playlist),
  ];

  static String _labelOf(AppTab tab, AppLocalizations l10n) => switch (tab) {
    AppTab.home => l10n.navHome,
    AppTab.library => l10n.navLibrary,
    AppTab.search => l10n.navSearch,
    AppTab.playlists => l10n.navPlaylists,
    AppTab.player => '',
  };

  @override
  Widget build(BuildContext context) {
    final glass = GlassTheme.bar(context);
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
          // ── Mini player section: slides in/out smoothly ─────────────────
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

          // ── Nav tabs row: visible only on root pages ────────────────────
          if (showTabs)
            SizedBox(
              height: AppSpacing.navBarHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: _tabs.map((tab) {
                      final (appTab, icon) = tab;
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
                          label: _labelOf(appTab, context.l10n),
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
          filter: GlassFilter.of(glass.blurSigma, saturation: glass.saturation),
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
/// A long press likes the song, or takes the like back: a heart pops over
/// its cover, with a light tick and a toast. Next keeps its button.
class _MiniPlayerRow extends StatefulWidget {
  final PlayerActive state;
  final BorderRadius radius;
  final bool showTabs;

  const _MiniPlayerRow({
    required this.state,
    required this.radius,
    this.showTabs = true,
  });

  @override
  State<_MiniPlayerRow> createState() => _MiniPlayerRowState();
}

class _MiniPlayerRowState extends State<_MiniPlayerRow> {
  /// Bumped by each like from here, with what it did.
  final _burst = ValueNotifier<(int, bool)>((0, false));

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  bool _isLiked(BuildContext context) => context
      .read<LikesCubit>()
      .state
      .isTrackLiked(widget.state.currentTrack.id);

  void _toggleLike(BuildContext context) {
    final track = widget.state.currentTrack;
    final liked = !_isLiked(context);
    context.read<LikesCubit>().toggle(track);
    AppHaptics.lightImpact();
    _burst.value = (_burst.value.$1 + 1, liked);
    AppToast.show(
      context,
      liked ? context.l10n.toastLiked : context.l10n.toastUnliked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final radius = widget.radius;
    final showTabs = widget.showTabs;
    final colors = context.colors;
    final glass = GlassTheme.miniPlayer(context);

    final likeLabel = _likeLabelOf(context);
    return Semantics(
      onLongPressHint: likeLabel,
      customSemanticsActions: {
        CustomSemanticsAction(label: likeLabel): () => _toggleLike(context),
      },
      child: Dismissible(
        key: ValueKey(state.currentTrack.id),
        direction: DismissDirection.down,
        onDismissed: (_) {
          context.read<PlayerBloc>().add(const PlayerDismissed());
        },
        child: GestureDetector(
          onTap: () => openFullPlayer(context),
          onLongPress: () => _toggleLike(context),
          onVerticalDragEnd: (d) {
            // Swipe up with sufficient velocity → open full player.
            if (d.velocity.pixelsPerSecond.dy < -300) {
              openFullPlayer(context);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: _CoveredFade(
            child: Container(
              height: AppSpacing.miniPlayerHeight,
              // Always a decoration, so toggling the tabs keeps the same element
              // tree and the heroes below survive (an interrupted flight
              // asserts if its hero is recreated).
              decoration: BoxDecoration(
                borderRadius: radius,
                border: showTabs
                    ? Border.all(width: 0, color: glass.border)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Landing spot of the Now Playing ring morph (invisible at
                    // rest: the bar itself draws the glass).
                    const Hero(
                      tag: NowPlayingHero.surfaceTag,
                      flightShuttleBuilder: NowPlayingHero.surfaceShuttle,
                      child: SizedBox.expand(),
                    ),
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

                        // A swipe on the song changes it: left for the next,
                        // right for the previous (not back to its start, as
                        // the button does past 3 s), like the Now Playing
                        // covers.
                        Expanded(
                          child: SwipeActions(
                            fadeChild: true,
                            onSwipeLeft: state.hasNext
                                ? () => context.read<PlayerBloc>().add(
                                    const SkipNextRequested(),
                                  )
                                : null,
                            onSwipeRight: state.hasPrevious
                                ? () => context.read<PlayerBloc>().add(
                                    QueueIndexRequested(
                                      state.queue.currentIndex - 1,
                                    ),
                                  )
                                : null,
                            child: Row(
                              children: [
                                // ── Artwork thumbnail ────────────────────────
                                SizedBox.square(
                                  dimension: 42,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          NowPlayingHero.miniArtworkRadius,
                                        ),
                                        child:
                                            state.currentTrack.artworkPath !=
                                                null
                                            ? Hero(
                                                tag: NowPlayingHero.artworkTag,
                                                flightShuttleBuilder:
                                                    NowPlayingHero
                                                        .artworkShuttle,
                                                // Full-size decode on purpose: this image
                                                // is also the morph shuttle's content.
                                                child: Image.file(
                                                  File(
                                                    state
                                                        .currentTrack
                                                        .artworkPath!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  gaplessPlayback: true,
                                                  errorBuilder: (_, _, _) =>
                                                      const ArtworkPlaceholder(),
                                                ),
                                              )
                                            : const ArtworkPlaceholder(),
                                      ),
                                      _LikeBurst(burst: _burst),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // ── Track title and artist ─────────────────────────────
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        context.artistName(
                                          state.currentTrack.artist,
                                        ),
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
                              ],
                            ),
                          ),
                        ),

                        // ── Play / Pause ───────────────────────────────────────
                        AppIconButton(
                          icon: state.isPlaying
                              ? AppIcons.pause
                              : AppIcons.play,
                          tooltip: state.isPlaying
                              ? context.l10n.playerPause
                              : context.l10n.actionPlay,
                          color: context.colors.labelPrimary,
                          onPressed: () {
                            context.read<PlayerBloc>().add(
                              state.isPlaying
                                  ? const PauseRequested()
                                  : const ResumeRequested(),
                            );
                          },
                        ),

                        // ── Skip next ──────────────────────────────────────────
                        AppIconButton(
                          icon: AppIcons.skipNext,
                          tooltip: context.l10n.playerNext,
                          color: context.colors.labelPrimary,
                          onPressed: state.hasNext
                              ? () {
                                  context.read<PlayerBloc>().add(
                                    const SkipNextRequested(),
                                  );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// What a long press does, for screen readers: like, or take it back.
  String _likeLabelOf(BuildContext context) {
    final likes = context.watch<LikesCubit?>();
    final liked =
        likes?.state.isTrackLiked(widget.state.currentTrack.id) ?? false;
    return liked ? context.l10n.likesRemove : context.l10n.trackLike;
  }
}

/// A heart that pops over the mini player's cover and fades: the like,
/// or a broken heart for one taken back. Still with reduced motion: the
/// toast says it.
class _LikeBurst extends StatefulWidget {
  final ValueNotifier<(int, bool)> burst;
  const _LikeBurst({required this.burst});

  @override
  State<_LikeBurst> createState() => _LikeBurstState();
}

class _LikeBurstState extends State<_LikeBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: .3,
        end: 1.25,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.25,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 25,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
  ]);

  @override
  void initState() {
    super.initState();
    widget.burst.addListener(_play);
  }

  @override
  void didUpdateWidget(_LikeBurst old) {
    super.didUpdateWidget(old);
    if (old.burst != widget.burst) {
      old.burst.removeListener(_play);
      widget.burst.addListener(_play);
    }
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    widget.burst.removeListener(_play);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.burst.value.$2;
    final colors = context.colors;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          return Opacity(
            opacity: t < .6 ? 1 : 1 - (t - .6) / .4,
            child: Transform.scale(
              scale: _scale.transform(t),
              child: Center(
                child: Icon(
                  key: const ValueKey('likeBurst'),
                  liked ? AppIcons.liked : AppIcons.unlike,
                  size: 28,
                  color: liked ? colors.accent : Colors.white,
                  shadows: const [
                    Shadow(color: Color(0x99000000), blurRadius: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hides the mini player row while the Now Playing route covers the shell,
/// so the morph lands in an empty glass slot. See
/// [NowPlayingHero.miniRowOpacity].
class _CoveredFade extends StatelessWidget {
  final Widget child;

  const _CoveredFade({required this.child});

  @override
  Widget build(BuildContext context) {
    // One stable structure: the row holds a hero that may be mid-flight
    // when the cover animation is published.
    return ValueListenableBuilder<Animation<double>?>(
      valueListenable: NowPlayingHero.coverAnimation,
      child: child,
      builder: (_, covering, child) {
        final animation = covering ?? kAlwaysDismissedAnimation;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (_, child) => Opacity(
            opacity: NowPlayingHero.miniRowOpacity(animation),
            child: child,
          ),
        );
      },
    );
  }
}

class _MiniPlayerProgressFill extends StatelessWidget {
  final Color progressTint;

  const _MiniPlayerProgressFill({required this.progressTint});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<PlaybackProgress>(
        valueListenable: context.read<PlayerBloc>().progress,
        builder: (_, p, _) => CustomPaint(
          painter: _FillPainter(
            ratio: (p.ratio * 200).round() / 200,
            tint: progressTint,
          ),
        ),
      ),
    );
  }
}

class _FillPainter extends CustomPainter {
  final double ratio;
  final Color tint;

  const _FillPainter({required this.ratio, required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    if (ratio <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * ratio, size.height),
      Paint()..color = tint,
    );
  }

  @override
  bool shouldRepaint(_FillPainter old) =>
      old.ratio != ratio || old.tint != tint;
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

          // Static disc: spinning a placeholder kept a ticker alive for
          // nothing. The reference design uses a static orb here.
          Positioned(
            child: RotatingArtwork(track: null, isPlaying: false, size: 56),
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

  static const _duration = Duration(milliseconds: 200);

  /// Size of the selection dot, and its distance below the icon's centre.
  static const dotSize = 4.0;
  static const dotOffset = 19.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Icon-only tabs: the label lives in semantics for screen readers.
    return Semantics(
      label: label,
      button: true,
      selected: isActive,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centred, in line with the artwork disc of the middle slot.
              AnimatedOpacity(
                duration: _duration,
                opacity: isActive ? 1.0 : 0.4,
                child: Icon(icon, color: colors.labelPrimary, size: 24),
              ),
              // The selected tab is told by more than its colour.
              Transform.translate(
                offset: const Offset(0, dotOffset),
                child: AnimatedScale(
                  duration: _duration,
                  curve: Curves.easeOutBack,
                  scale: isActive ? 1 : 0,
                  child: DecoratedBox(
                    key: const ValueKey('tabDot'),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: dotSize),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
