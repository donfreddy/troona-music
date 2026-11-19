import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/foundation.dart';
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
import 'package:troona/shared/widgets/edge_fade.dart';
import 'package:troona/shared/widgets/glass_edge.dart';
import 'package:troona/shared/widgets/like_burst.dart';
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

  /// How open an empty mini player slot is above the tabs, 0 to 1; null
  /// for none. Now Playing's own bar, which has no mini player, opens it
  /// while the surface comes down on dismiss: the bar grows to the height
  /// of the shell's, and the surface lands inside it instead of settling
  /// above a bar of tabs only.
  final Animation<double>? miniSlot;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.showMiniPlayer = true,
    this.showTabs = true,
    this.miniSlot,
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
              miniSlot: widget.miniSlot,
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
      // The mini player's carousel shows them and swipes to them; what
      // Next does depends on the repeat mode.
      s.queue.currentIndex,
      s.queue.repeatMode,
      _neighbourOf(s, -1)?.id,
      _neighbourOf(s, 1)?.id,
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
  final Animation<double>? miniSlot;

  const _NavBarBody({
    required this.currentTab,
    required this.onTabChanged,
    required this.playerState,
    required this.showMiniPlayer,
    required this.showTabs,
    required this.miniSlot,
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
      decoration: BoxDecoration(color: glass.fill, borderRadius: radius),
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

          // ── Empty mini player slot: the glass alone, as tall as the row ─
          if (miniSlot case final slot?)
            SizeTransition(
              key: const ValueKey('miniSlot'),
              sizeFactor: slot,
              child: const SizedBox(height: AppSpacing.miniPlayerHeight),
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

    final edged = CustomPaint(
      foregroundPainter: GlassEdgePainter.of(glass, borderRadius: radius),
      child: body,
    );
    // Lifts the floating bar off the page, painted outside it only and
    // after it: a shadow in the backdrop, even beside the bar, darkens the
    // glass, whose blur samples well past its edge.
    final shadow = OuterShadowPainter(borderRadius: radius);

    if (glass.blurSigma == 0) {
      return CustomPaint(
        foregroundPainter: shadow,
        child: ClipRRect(borderRadius: radius, child: edged),
      );
    }

    // RepaintBoundary isolates the BackdropFilter compositing layer so
    // position-stream rebuilds above in the tree do not trigger a re-blur.
    return CustomPaint(
      foregroundPainter: shadow,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: GlassFilter.of(
              glass.blurSigma,
              saturation: glass.saturation,
              exposure: glass.exposure,
            ),
            child: edged,
          ),
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

class _MiniPlayerRowState extends State<_MiniPlayerRow>
    with TickerProviderStateMixin {
  /// Bumped by each like from here, with what it did.
  final _burst = LikeBurstController();

  // ── Song carousel ─────────────────────────────────────────────────────────

  /// How far the titles are moved, in pixels: negative toward the next
  /// song. The song playing sits at it, its neighbours one [_span] away.
  late final _slide = AnimationController.unbounded(vsync: this);

  /// The last change of song, 0 to 1: the old cover fades out over the new
  /// one (and the old text, for a change that does not slide).
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  )..addStatusListener(_onFadeStatus);

  /// Width of the text area, from its last layout: the distance between
  /// two songs' titles.
  double _span = 0;

  /// Whether the finger is past the threshold.
  bool _armed = false;

  /// The drag under way, if any: where the titles were when it began (they
  /// may still be settling from the last change) and how far the finger
  /// went since. Its way and threshold read the finger, never the titles.
  bool _dragLive = false;
  double _dragOrigin = 0;
  double _dragDelta = 0;

  /// The song a swipe (or Next) asked for: its queue index, id and
  /// direction (1 for the next song), until the player gets there or
  /// [_giveUp] fires.
  int? _awaitIndex;
  String? _awaitTrackId;
  int _awaitStep = 0;
  Timer? _giveUp;

  /// The song before the last change, while [_fade] runs.
  Track? _from;

  /// Whether the last change fades the text instead of sliding it.
  bool _fadeText = false;

  static const _threshold = 72.0;
  static const _travel = Duration(milliseconds: 300);

  /// How long a swipe waits for the player before putting the song back.
  static const _patience = Duration(milliseconds: 700);

  /// How far the row is swiped down, 0 to 1 of its height: the bar's top
  /// edge follows the finger and the row fades; let go far or fast enough,
  /// the row closes and the player stops.
  late final _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  /// Whether the row was swiped away, until the player goes idle and the
  /// row leaves (or a new song plays and brings it back).
  bool _dismissed = false;

  /// Songs queued by hand lately, for [_QueuedAck]. Held here, so skipping
  /// right after Play next keeps the count.
  final _queued = ValueNotifier<_Queued>((count: 0, shown: false, serial: 0));
  late final StreamSubscription<PlayerNotice> _notices;
  Timer? _queuedHide;

  @override
  void initState() {
    super.initState();
    _notices = context.read<PlayerBloc>().notices.listen(_onNotice);
  }

  void _onNotice(PlayerNotice notice) {
    if (notice is! TrackQueued) return;
    final last = _queued.value;
    _queued.value = (
      count: (last.shown ? last.count : 0) + notice.count,
      shown: true,
      serial: last.serial + 1,
    );
    _queuedHide?.cancel();
    _queuedHide = Timer(_QueuedAck.shown, () {
      final last = _queued.value;
      _queued.value = (count: last.count, shown: false, serial: last.serial);
    });
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _onFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _from != null) {
      setState(() => _from = null);
    }
  }

  @override
  void didUpdateWidget(_MiniPlayerRow old) {
    super.didUpdateWidget(old);
    final before = old.state;
    final now = widget.state;
    // The song asked for, where it was asked for: a queue edit meanwhile
    // that puts another song there, or this one elsewhere, is not it.
    final awaited =
        _awaitIndex != null &&
        now.queue.currentIndex == _awaitIndex &&
        now.currentTrack.id == _awaitTrackId &&
        now.queue.currentTrack?.id == now.currentTrack.id;
    if (before.currentTrack.id != now.currentTrack.id && _dismissed) {
      // A song played while the row was leaving: it stays.
      _dismissed = false;
      _drop.value = 0;
    }
    if (!awaited && before.currentTrack.id == now.currentTrack.id) return;

    // Only a change asked for here slides, the way it was asked; one from
    // elsewhere (a song ending, Now Playing, the queue) fades.
    final step = awaited ? _awaitStep : 0;
    _giveUp?.cancel();
    _awaitIndex = null;
    _awaitTrackId = null;
    // A song changed under the finger: that drag was about the old one.
    _dragLive = false;
    _armed = false;
    _from = before.currentTrack;
    _fade.forward(from: 0);
    _slide.stop();
    if (step == 0 || _span <= 0 || _reduceMotion) {
      _fadeText = true;
      _slide.value = 0;
      return;
    }
    // The new song's title was a neighbour, [step] spans along: it carries
    // on from there to the middle, and the old one leaves the other way.
    _fadeText = false;
    _slide.value = (_slide.value + step * _span).clamp(-_span, _span);
    _settle();
  }

  /// Back to rest, over a time that follows the distance left.
  void _settle() {
    if (_span <= 0 || _reduceMotion) {
      _slide.value = 0;
      return;
    }
    final left = (_slide.value.abs() / _span).clamp(0.0, 1.0);
    _slide.animateTo(
      0,
      duration: _travel * math.max(left, .4),
      curve: Curves.easeOutCubic,
    );
  }

  /// Waits for [target], [step] along, asked for by a swipe or Next.
  void _await(int target, int step) {
    _awaitIndex = target;
    _awaitTrackId = widget.state.queue.playbackTracks[target].id;
    _awaitStep = step;
    _giveUp?.cancel();
  }

  void _clearAwait() {
    _awaitIndex = null;
    _awaitTrackId = null;
  }

  void _onDragStart(DragStartDetails details) {
    // A swipe already sent: the next one waits for its song, and a drag
    // begun meanwhile stays dead, even once that swipe gives up.
    _dragLive = _awaitIndex == null && _span > 0;
    if (!_dragLive) return;
    _slide.stop();
    _dragOrigin = _slide.value;
    _dragDelta = 0;
    _armed = false;
  }

  /// The way the finger went: 1 toward the next song, -1 the previous.
  int get _dragStep => _dragDelta < 0 ? 1 : (_dragDelta > 0 ? -1 : 0);

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragLive) return;
    _dragDelta += details.primaryDelta ?? 0;
    final step = _dragStep;
    final target = step == 0 ? null : _neighbourIndex(widget.state, step);
    // Without a song that way, the finger meets resistance.
    final moved = step != 0 && target == null ? _dragDelta * .2 : _dragDelta;
    final armed = target != null && _dragDelta.abs() >= _threshold;
    if (armed != _armed) AppHaptics.selectionClick();
    _armed = armed;
    _slide.value = (_dragOrigin + moved).clamp(-_span, _span);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragLive) return;
    _dragLive = false;
    final velocity = details.primaryVelocity ?? 0;
    final step = _dragStep;
    final target = step == 0 ? null : _neighbourIndex(widget.state, step);
    final flung =
        velocity.abs() >= SwipeActions.flingVelocity &&
        velocity.sign == _dragDelta.sign;
    final armed = _armed;
    _armed = false;
    if (target == null || !(armed || flung)) {
      _settle();
      return;
    }
    if (!armed) AppHaptics.selectionClick();
    // By index, as the Now Playing covers do: under repeat one, Next
    // would replay the song.
    context.read<PlayerBloc>().add(QueueIndexRequested(target));
    _await(target, step);
    if (_reduceMotion) {
      // Nothing slides: the songs fade once the player gets there.
      _slide.value = 0;
      _giveUp = Timer(_patience, _clearAwait);
      return;
    }
    // The neighbour comes to the middle while the player gets there.
    final end = -step * _span;
    final left = ((end - _slide.value).abs() / _span).clamp(0.0, 1.0);
    _slide
        .animateTo(
          end,
          duration: _travel * math.max(left, .4),
          curve: Curves.easeOutCubic,
        )
        .whenCompleteOrCancel(() {
          if (!mounted || _awaitIndex != target) return;
          // Still the old song: give the player a moment, then put it back.
          _giveUp?.cancel();
          _giveUp = Timer(_patience, () {
            if (!mounted || _awaitIndex != target) return;
            _clearAwait();
            _settle();
          });
        });
  }

  /// Next, from the button: the engine's own next (under repeat one, the
  /// song again), and the titles slide once it gets there. Not while a
  /// swipe waits for its song, or during a drag: both would move on, in
  /// either order.
  void _onNextPressed() {
    if (_awaitIndex != null || _dragLive) return;
    context.read<PlayerBloc>().add(const SkipNextRequested());
    final target = _neighbourIndex(widget.state, 1);
    // Waits only for the song the engine goes to: under repeat one it
    // replays this one, and nothing would come.
    final queue = widget.state.queue;
    if (target == null ||
        queue.nextTrack?.id != queue.playbackTracks[target].id) {
      return;
    }
    _await(target, 1);
    _giveUp = Timer(_patience, _clearAwait);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_dismissed) return;
    _drop.stop();
    _drop.value += (details.primaryDelta ?? 0) / AppSpacing.miniPlayerHeight;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dismissed) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      // Up, fast enough: Now Playing.
      _dropBack();
      openFullPlayer(context);
      return;
    }
    if (_drop.value < .4 && velocity < SwipeActions.flingVelocity) {
      _dropBack();
      return;
    }
    _dismissed = true;
    void stop() {
      // Not if a song played meanwhile and brought the row back.
      if (!mounted || !_dismissed) return;
      context.read<PlayerBloc>().add(const PlayerDismissed());
    }

    if (_reduceMotion) {
      _drop.value = 1;
      stop();
    } else {
      _drop.animateTo(1, curve: Curves.easeOutCubic).whenComplete(stop);
    }
  }

  void _dropBack() {
    if (_dismissed) return;
    if (_reduceMotion) {
      _drop.value = 0;
    } else {
      _drop.animateBack(0, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    _drop.dispose();
    _slide.dispose();
    _fade.dispose();
    _queuedHide?.cancel();
    _notices.cancel();
    _queued.dispose();
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
    _burst.play(liked: liked);
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
    final tint = GlassTheme.miniPlayerTint(context);

    final likeLabel = _likeLabelOf(context);
    return Semantics(
      onLongPressHint: likeLabel,
      customSemanticsActions: {
        CustomSemanticsAction(label: likeLabel): () => _toggleLike(context),
      },
      // Nothing below is keyed by song: a change keeps it all (the cover
      // shows the old image until the new one is decoded).
      child: _DropOut(
        drop: _drop,
        child: GestureDetector(
          onTap: () => openFullPlayer(context),
          onLongPress: () => _toggleLike(context),
          // Both ways in one place: a second vertical recognizer (a
          // Dismissible) would never win against this one.
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          onVerticalDragCancel: _dropBack,
          behavior: HitTestBehavior.opaque,
          child: _CoveredFade(
            child: Container(
              height: AppSpacing.miniPlayerHeight,
              // Always a decoration, so toggling the tabs keeps the same element
              // tree and the heroes below survive (an interrupted flight
              // asserts if its hero is recreated).
              decoration: BoxDecoration(
                borderRadius: radius,
                border: showTabs ? Border.all(width: 0, color: tint) : null,
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
                      createRectTween: NowPlayingHero.flightTween,
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
                    _MiniPlayerProgressFill(progressTint: tint),
                    Row(
                      children: [
                        const SizedBox(width: 12),

                        // A swipe on the song changes it: left for the next,
                        // right for the previous (not back to its start, as
                        // the button does past 3 s), like the Now Playing
                        // covers. Only the titles move: the neighbour's
                        // shows as the finger goes, and the cover stays,
                        // taking the new song's.
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onHorizontalDragStart: _onDragStart,
                            onHorizontalDragUpdate: _onDragUpdate,
                            onHorizontalDragEnd: _onDragEnd,
                            onHorizontalDragCancel: () =>
                                _onDragEnd(DragEndDetails()),
                            child: Row(
                              children: [
                                // ── Artwork thumbnail ────────────────────────
                                _QueuedAck(
                                  queued: _queued,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          NowPlayingHero.miniArtworkRadius,
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _MiniArtwork(
                                              path: state
                                                  .currentTrack
                                                  .artworkPath,
                                              hero: true,
                                            ),
                                            // The old cover, fading out over
                                            // the new one (outside the hero:
                                            // it never flies).
                                            if (_from case final from?)
                                              IgnorePointer(
                                                child: FadeTransition(
                                                  opacity: ReverseAnimation(
                                                    _fade,
                                                  ),
                                                  child: _MiniArtwork(
                                                    path: from.artworkPath,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      LikeBurst(controller: _burst),
                                    ],
                                  ),
                                ),

                                // ── Track title and artist ─────────────────────
                                Expanded(child: _carousel(state)),
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
                          onPressed: state.hasNext ? _onNextPressed : null,
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

  /// Width of the edge fades while titles move: the leading one covers the
  /// gap after the cover, the trailing one matches [Marquee]'s.
  static const _leadFade = 12.0;
  static const _trailFade = 16.0;

  /// The lines of the song playing and, while they move, its neighbours',
  /// each fading with its distance from the middle. While they move, both
  /// edges fade: a title never meets a hard cut. At rest nothing crosses
  /// them, and the lines show as they always did (a long title fades on its
  /// own, an artist ends on an ellipsis).
  Widget _carousel(PlayerActive state) {
    final previous = _neighbourOf(state, -1);
    final next = _neighbourOf(state, 1);
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final span = _span = constraints.maxWidth;
          if (span <= 0) return const SizedBox.shrink();
          return AnimatedBuilder(
            animation: Listenable.merge([_slide, _fade]),
            builder: (context, _) {
              final dx = _slide.value;
              final from = _fadeText ? _from : null;
              final fadeIn = from == null ? 1.0 : _fade.value;
              // Keyed by role: a neighbour coming or going keeps the song
              // playing's lines (and their marquee) in place.
              Widget? slot(
                String role,
                Track? track,
                double at, {
                double opacity = 1,
              }) {
                if (track == null) return null;
                final current = role == 'current';
                final shown = opacity * (1 - at.abs() / span).clamp(0.0, 1.0);
                // The song playing stays built, faded out or not: its lines
                // keep their state, and screen readers read them.
                if (shown <= 0 && !current) return null;
                Widget lines = _SongLines(track: track);
                if (!current) lines = ExcludeSemantics(child: lines);
                return Positioned.fill(
                  key: ValueKey(role),
                  child: Transform.translate(
                    offset: Offset(at, 0),
                    child: Opacity(
                      opacity: shown,
                      alwaysIncludeSemantics: current,
                      child: lines,
                    ),
                  ),
                );
              }

              return EdgeFade(
                active: dx != 0,
                start: _leadFade,
                end: _trailFade,
                child: ClipRect(
                  child: Stack(
                    children: [
                      ?slot('from', from, 0, opacity: 1 - fadeIn),
                      ?slot('previous', previous, dx - span),
                      ?slot('current', state.currentTrack, dx, opacity: fadeIn),
                      ?slot('next', next, dx + span),
                    ],
                  ),
                ),
              );
            },
          );
        },
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

/// Shrinks the mini player row by [drop] of its height from the top,
/// fading it out: the bar's top edge comes down with the finger, in one
/// movement. Once the row is gone, the bar has nothing left to shrink when
/// the player goes idle.
class _DropOut extends StatelessWidget {
  final Animation<double> drop;
  final Widget child;

  const _DropOut({required this.drop, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: drop,
    child: child,
    builder: (context, child) => ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1 - drop.value,
        child: Opacity(opacity: 1 - drop.value, child: child),
      ),
    ),
  );
}

/// The queue index a swipe on the mini player goes to: the song after
/// ([step] 1) or before (-1) in playback order, wrapping round only under
/// repeat all. Not [Queue.nextTrack]: under repeat one that is the song
/// itself, and a swipe changes song, as the Now Playing covers do.
int? _neighbourIndex(PlayerActive state, int step) {
  final queue = state.queue;
  // While a new song loads, the queue may still be the old one.
  if (queue.currentTrack?.id != state.currentTrack.id) return null;
  final index = queue.currentIndex + step;
  if (index >= 0 && index < queue.length) return index;
  if (queue.repeatMode != RepeatMode.all || queue.length < 2) return null;
  return index < 0 ? queue.length - 1 : 0;
}

Track? _neighbourOf(PlayerActive state, int step) =>
    switch (_neighbourIndex(state, step)) {
      final index? => state.queue.playbackTracks[index],
      null => null,
    };

/// A song's title and artist, as the mini player shows them. Each slot of
/// the carousel draws one, so a neighbour coming in already looks as it
/// will once it plays (a long title fades out, it is not ellipsized).
class _SongLines extends StatelessWidget {
  final Track track;
  const _SongLines({required this.track});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: _MiniPlayerRowState._leadFade,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Marquee(
            text: track.title,
            style: TextStyle(
              color: colors.labelPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            context.artistName(track.artist),
            style: TextStyle(color: colors.labelSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The mini player's cover, decoded at full size on purpose: the hero's
/// image is also the Now Playing morph's shuttle, and the old cover fading
/// out after a change reads the image already cached.
class _MiniArtwork extends StatelessWidget {
  final String? path;

  /// Whether this is the cover that flies into Now Playing.
  final bool hero;

  const _MiniArtwork({required this.path, this.hero = false});

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    if (path == null) return const ArtworkPlaceholder();
    final image = Image.file(
      File(path),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const ArtworkPlaceholder(),
    );
    if (!hero) return image;
    return Hero(
      tag: NowPlayingHero.artworkTag,
      createRectTween: NowPlayingHero.flightTween,
      flightShuttleBuilder: NowPlayingHero.artworkShuttle,
      child: image,
    );
  }
}

/// Songs queued by hand lately: how many, whether the count shows, and
/// a serial bumped by each action.
typedef _Queued = ({int count, bool shown, int serial});

/// Acknowledges songs queued by hand ([TrackQueued]) on the mini player's
/// cover: it pulses once and a "+N" counts them, then leaves [shown] after
/// the last action. Queueing an album is one action: one pulse, its songs
/// counted at once.
class _QueuedAck extends StatefulWidget {
  final ValueListenable<_Queued> queued;
  final Widget child;
  const _QueuedAck({required this.queued, required this.child});

  static const size = 42.0;
  static const shown = Duration(milliseconds: 1500);

  @override
  State<_QueuedAck> createState() => _QueuedAckState();
}

class _QueuedAckState extends State<_QueuedAck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.1,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.1,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 60,
    ),
  ]);

  /// The last action seen: a new serial is a new action, a change of
  /// [_Queued.shown] alone is not.
  late int _serial;

  @override
  void initState() {
    super.initState();
    _serial = widget.queued.value.serial;
    widget.queued.addListener(_changed);
    NowPlayingHero.coverAnimation.addListener(_covered);
  }

  /// Now Playing coming over the row: a pulse under way stops, so the cover
  /// flies from its place at rest.
  void _covered() {
    if (NowPlayingHero.coverAnimation.value != null && _pulse.isAnimating) {
      _pulse.value = 0;
    }
  }

  @override
  void didUpdateWidget(_QueuedAck old) {
    super.didUpdateWidget(old);
    if (old.queued != widget.queued) {
      old.queued.removeListener(_changed);
      widget.queued.addListener(_changed);
    }
  }

  void _changed() {
    final serial = widget.queued.value.serial;
    final queuedNow = serial != _serial;
    _serial = serial;
    setState(() {});
    if (queuedNow && _canPulse) _pulse.forward(from: 0);
  }

  /// Not with reduced motion, not twice at once, and not while Now Playing
  /// covers the row: the cover is a hero, and growing it would move where
  /// the flight lands.
  bool get _canPulse =>
      !MediaQuery.disableAnimationsOf(context) &&
      !_pulse.isAnimating &&
      NowPlayingHero.coverAnimation.value == null;

  @override
  void dispose() {
    widget.queued.removeListener(_changed);
    NowPlayingHero.coverAnimation.removeListener(_covered);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (:count, :shown, serial: _) = widget.queued.value;
    return SizedBox.square(
      dimension: _QueuedAck.size,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          ScaleTransition(scale: _pulse.drive(_scale), child: widget.child),
          // The toast of the action says it to screen readers.
          Positioned(
            top: -6,
            right: -8,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedOpacity(
                  opacity: shown ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    key: const ValueKey('queuedBadge'),
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      '+$count',
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.accentForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // One step per physical pixel: each position tick moves the fill
          // like the Now Playing ring, and a long track repaints only when
          // the edge actually moves. Coarser steps (a 200th of the bar)
          // made it stop and go.
          final pixels =
              constraints.maxWidth * MediaQuery.devicePixelRatioOf(context);
          return ValueListenableBuilder<PlaybackProgress>(
            valueListenable: context.read<PlayerBloc>().progress,
            builder: (_, p, _) => CustomPaint(
              key: const ValueKey('miniPlayerFill'),
              painter: _FillPainter(
                ratio: pixels.isFinite && pixels > 0
                    ? (p.ratio * pixels).round() / pixels
                    : p.ratio,
                tint: progressTint,
              ),
            ),
          );
        },
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

  /// The other tabs: readable over a light cover under the bar's glass,
  /// still a step below the selected one (and its dot).
  static const inactiveOpacity = 0.6;

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
                opacity: isActive ? 1.0 : inactiveOpacity,
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
