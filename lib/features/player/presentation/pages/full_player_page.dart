import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_state.dart';
import 'package:troona/features/lyrics/presentation/widgets/lyrics_actions.dart';
import 'package:troona/shared/widgets/action_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:troona/shared/widgets/like_burst.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/theme/components/blur_budget.dart';
import 'package:go_router/go_router.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:troona/features/lyrics/presentation/cubit/lyrics_cubit.dart';
import 'package:troona/features/lyrics/presentation/widgets/keep_screen_on.dart';
import 'package:troona/features/lyrics/presentation/widgets/lyrics_view.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/artwork_carousel.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/features/player/presentation/widgets/player_progress_bar.dart';
import 'package:troona/features/player/presentation/widgets/player_utility_dock.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/features/player/presentation/widgets/progress_ring.dart';
import 'package:troona/features/player/presentation/widgets/queue_sheet.dart';
import 'package:troona/features/player/presentation/widgets/track_title_switcher.dart';
import 'package:troona/features/library/presentation/widgets/track_actions/show_track_actions.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/palette_ink_scope.dart';
import 'package:troona/core/extensions/context_ext.dart';

class FullPlayerPage extends StatefulWidget {
  const FullPlayerPage({super.key, this.morphFromMini = true});

  static const routeName = '/player';

  /// Route `extra` that opens the page without the mini player morph.
  static const noMorph = 'full-player-no-morph';

  /// False when the mini player is not laid out yet (session restore at
  /// launch): the morph would start from a clipped, zero-height rect. The
  /// dismiss morph is enabled once the page is shown.
  final bool morphFromMini;

  @override
  State<FullPlayerPage> createState() => _FullPlayerPageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag-to-dismiss constants
// ─────────────────────────────────────────────────────────────────────────────

/// Minimum downward velocity (px/s) that triggers an instant dismiss.
const double _kDismissVelocity = 400;

/// Minimum upward velocity (px/s) that opens the queue.
const double _kQueueVelocity = 600;

/// Minimum drag distance (fraction of screen height) that triggers dismiss.
const double _kDismissThreshold = 0.25;

/// Maximum opacity reduction at the edge of the dismiss threshold.
const double _kMaxOpacityReduction = 0.35;

/// The utility dock and the playback controls, with a minimal gap around
/// each: the stage above never takes this room.
const double _kControlsBlock =
    PlayerUtilityDock.height + PlayerControls.height + 3 * AppSpacing.md;

class _FullPlayerPageState extends State<FullPlayerPage>
    with TickerProviderStateMixin {
  // ── Drag-to-dismiss state ─────────────────────────────────────────────────
  late final AnimationController _snapBack;
  late Animation<double> _snapAnim;
  double _dragOffset = 0;
  Track? _lastResolvedTrack;

  /// Last queue shown by the carousel, kept while the next track loads so
  /// the stage is not unmounted (and its scroll state lost) on every swipe.
  List<Track> _stageQueue = const [];
  int _stageIndex = 0;

  /// The heart's answer to a like, from its button or the menu.
  final _likeBurst = LikeBurstController();

  /// Whether the lyrics stand in for the stage. The stage stays mounted
  /// below them, unseen, and keeps its heroes: the page still morphs into
  /// the mini player, the cover coming out of the lyrics on its way
  /// ([NowPlayingStage]). Kept from one opening to the next.
  late bool _lyricsShown = getIt<PlaybackSessionStore>().wereLyricsShown;

  /// Made the first time the lyrics are shown, for this page only.
  LyricsCubit? _lyrics;

  /// 0 the stage, 1 the lyrics: the two cross-fade, the lyrics take the
  /// room down to the controls and the tab bar slides away.
  late final AnimationController _lyricsMix = AnimationController(
    vsync: this,
    duration: lyricsSwitch,
    value: _lyricsShown ? 1 : 0,
  );

  /// The stage goes first, then the lyrics come: never both at full
  /// strength over each other.
  late final CurvedAnimation _stageOut = CurvedAnimation(
    parent: _lyricsMix,
    curve: const Interval(0, 0.6, curve: Curves.easeIn),
  );
  late final Animation<double> _stageOpacity = ReverseAnimation(_stageOut);
  late final CurvedAnimation _lyricsIn = CurvedAnimation(
    parent: _lyricsMix,
    curve: const Interval(0.4, 1, curve: Curves.easeOut),
  );
  late final Animation<Offset> _lyricsRise = Tween(
    begin: const Offset(0, 0.03),
    end: Offset.zero,
  ).animate(_lyricsIn);

  /// The room the lyrics take, and how far the tab bar is down.
  late final CurvedAnimation _lyricsRoom = CurvedAnimation(
    parent: _lyricsMix,
    curve: Curves.easeInOutCubic,
  );

  /// How long the switch between the stage and the lyrics takes.
  static const lyricsSwitch = Duration(milliseconds: 340);

  LyricsCubit _lyricsCubit() => _lyrics ??= LyricsCubit.of(
    getIt<LyricsRepository>(),
    context.read<PlayerBloc>(),
  );

  void _toggleLyrics() {
    final lyrics = _lyricsCubit();
    setState(() => _lyricsShown = !_lyricsShown);
    lyrics.setVisible(_lyricsShown);
    unawaited(getIt<PlaybackSessionStore>().setLyricsShown(_lyricsShown));
    if (MediaQuery.disableAnimationsOf(context)) {
      _lyricsMix.value = _lyricsShown ? 1 : 0;
    } else if (_lyricsShown) {
      _lyricsMix.forward();
    } else {
      _lyricsMix.reverse();
    }
  }

  /// The lyrics stay mounted until they have faded out: rebuilt once the
  /// switch is over, either way.
  void _onLyricsMixStatus(AnimationStatus status) {
    if (mounted && !status.isAnimating) setState(() {});
  }

  /// Index the user swiped to, used to disambiguate duplicate tracks while
  /// the requested track loads.
  int? _requestedStageIndex;

  /// Stage page a swipe is heading to: the title shows its track during
  /// the swipe instead of waiting for the bloc. Null otherwise.
  final _swipeFocus = ValueNotifier<int?>(null);

  /// The carousel also reports from didUpdateWidget, when the player
  /// follows a swipe. It is built inside the stage's LayoutBuilder, so that
  /// happens during layout, where the title (outside that builder) cannot
  /// be marked for rebuild: it is told after the frame instead.
  void _onSwipeFocusChanged(int? page) {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      _swipeFocus.value = page;
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _swipeFocus.value = page;
    });
  }

  // ── Carousel / likes ──────────────────────────────────────────────────────
  void _onCarouselPageChanged(int index) {
    if (index == _stageIndex || index >= _stageQueue.length) return;
    final bloc = context.read<PlayerBloc>();
    final state = bloc.state;
    // Swiping within the playing queue: jump to the index so the queue is
    // kept as is (rebuilding it would reshuffle in shuffle mode).
    if (state is PlayerActive &&
        listEquals(state.queue.playbackTracks, _stageQueue)) {
      bloc.add(QueueIndexRequested(index));
      return;
    }
    _requestedStageIndex = index;
    bloc.add(
      PlayTrackRequested(
        _stageQueue[index],
        contextQueue: _stageQueue,
        contextIndex: index,
      ),
    );
  }

  /// Queue and index for the carousel; null when nothing was ever loaded.
  (List<Track>, int)? _resolveStage(PlayerState state) {
    switch (state) {
      case PlayerActive(:final queue):
        _requestedStageIndex = null;
        _stageQueue = queue.playbackTracks;
        _stageIndex = queue.currentIndex;
      case PlayerLoading(:final track):
        // Keep the swiped index when it already holds this track: a queue
        // may contain the same track twice.
        final requested = _requestedStageIndex;
        if (requested != null &&
            requested < _stageQueue.length &&
            _stageQueue[requested].id == track.id) {
          _stageIndex = requested;
        } else {
          final index = _stageQueue.indexWhere((t) => t.id == track.id);
          if (index < 0) {
            _stageQueue = [track];
            _stageIndex = 0;
          } else {
            _stageIndex = index;
          }
        }
      case PlayerIdle():
        // Dismissed: never replay or animate across a stale queue.
        _stageQueue = const [];
        _stageIndex = 0;
        _requestedStageIndex = null;
        // The carousel goes away without reporting the end of a drag.
        _swipeFocus.value = null;
      case PlayerError():
        break;
    }
    if (_stageQueue.isEmpty) return null;
    return (_stageQueue, _stageIndex.clamp(0, _stageQueue.length - 1));
  }

  @override
  void initState() {
    super.initState();

    _snapAnim = const AlwaysStoppedAnimation(0);
    _snapBack =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 280),
        )..addListener(() {
          if (!mounted) return;
          setState(() => _setDragOffset(_snapAnim.value));
        });

    _lyricsMix.addStatusListener(_onLyricsMixStatus);
    // Left on its lyrics: opened on them.
    if (_lyricsShown) _lyricsCubit().setVisible(true);

    final playerState = context.read<PlayerBloc>().state;
    final initialTrack = _resolveTrack(playerState);
    if (initialTrack != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<LikesCubit>().syncTrack(initialTrack);
        }
      });
    }
  }

  /// Chrome (top bar, title, controls) fades in on the last half of the
  /// route animation. On dismiss it goes at once (a third of it after a
  /// fifth of the time, all of it by two fifths), before the surface
  /// leaves the ring, as in the reference.
  CurvedAnimation? _chrome;

  /// The page's background and its tab bar. They cover the page below
  /// within the first 45 % of the opening, and on dismiss stay opaque for
  /// the first 55 %, while the surface flies: the page below shows only
  /// once the surface has nearly landed. A fade of the whole page showed
  /// two screens on top of each other all the way.
  CurvedAnimation? _backdrop;

  /// How closed the empty mini player slot of the page's own tab bar is.
  /// On dismiss the bar opens it while the surface comes down, and is as
  /// tall as the shell's bar by the time the background starts to go: the
  /// surface lands inside a bar already open for it, not above a bar of
  /// tabs only that the shell's then replaces. On open the slot closes
  /// once the background covers the shell's bar, the surface gone.
  CurvedAnimation? _slotClosed;

  /// [_slotClosed] the other way round, for the bar: 1 is open.
  Animation<double>? _slot;

  /// Lens and progress arc: they sit exactly where the surface shuttle
  /// lands, so they appear only once it has arrived (and go first on
  /// dismiss); earlier, they would frame the still-small shuttle.
  CurvedAnimation? _stage;

  /// Route animation curved like the hero flight, published to the mini
  /// player row through [NowPlayingHero.coverAnimation].
  CurvedAnimation? _cover;

  late bool _heroes = widget.morphFromMini;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeAnimation = ModalRoute.of(context)?.animation;
    if (routeAnimation != null && _chrome?.parent != routeAnimation) {
      _chrome?.parent.removeStatusListener(_enableHeroesOnceShown);
      _chrome?.dispose();
      _backdrop?.dispose();
      _slotClosed?.dispose();
      _stage?.dispose();
      _cover?.dispose();
      // Right after the background's own interval, and one curve both
      // ways: nothing jumps when a dismiss is turned back into an open.
      final slotClosed = _slotClosed = CurvedAnimation(
        parent: routeAnimation,
        curve: const Interval(0.45, 0.8, curve: Curves.easeInOutCubic),
      );
      _slot = ReverseAnimation(slotClosed);
      _chrome = CurvedAnimation(
        parent: routeAnimation,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
        reverseCurve: const Interval(0.6, 1, curve: Curves.easeIn),
      );
      _chromeOrDrag = AnimationMin<double>(_chrome!, _dragFade);
      _backdrop = CurvedAnimation(
        parent: routeAnimation,
        curve: const Interval(0, 0.45, curve: Curves.easeOut),
      );
      _stage = CurvedAnimation(
        parent: routeAnimation,
        curve: const Interval(0.75, 1, curve: Curves.easeOut),
      );
      // Created while the route is still moving forward, so its curve
      // direction follows the flight's, diverted flights included.
      _cover = NowPlayingHero.curveLikeFlight(routeAnimation);
      if (!_heroes) {
        if (routeAnimation.isCompleted) {
          _heroes = true;
        } else {
          routeAnimation.addStatusListener(_enableHeroesOnceShown);
        }
      }
      _publishCover(_cover, replacing: null);
    }
  }

  /// Hands the cover animation to the mini player row. Deferred: the row
  /// lives in another subtree, which must not be marked dirty mid-build or
  /// while the tree is locked on dispose.
  static void _publishCover(
    Animation<double>? animation, {
    required Animation<double>? replacing,
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final cover = NowPlayingHero.coverAnimation;
      if (replacing == null || cover.value == replacing) {
        cover.value = animation;
      }
    });
  }

  void _enableHeroesOnceShown(AnimationStatus status) {
    if (!status.isCompleted) return;
    _chrome?.parent.removeStatusListener(_enableHeroesOnceShown);
    if (mounted) setState(() => _heroes = true);
  }

  /// Opacity of the chrome and the neighbour covers while the content is
  /// dragged down; set by hand, never run.
  late final AnimationController _dragFade = AnimationController(
    vsync: this,
    value: 1,
  );

  /// [_chrome] and [_dragFade] together: the drag reuses the fade the
  /// chrome already has instead of adding a layer of its own.
  Animation<double>? _chromeOrDrag;

  void _setDragOffset(double offset) {
    _dragOffset = offset;
    final screenH = MediaQuery.sizeOf(context).height;
    _dragFade.value =
        1.0 - (offset / screenH).clamp(0.0, _kMaxOpacityReduction);
  }

  /// [glass]: the child blurs what is behind it. It keeps its opacity
  /// while dragged: under an opacity layer a blur samples that empty
  /// layer, not the background, and would show no frost at all.
  Widget _fadeChrome(Widget child, {bool glass = false}) =>
      _fade(glass ? _chrome : _chromeOrDrag, child);

  /// The stage in the room [height] leaves it, with the lyrics over it
  /// when shown. One structure either way, so the carousel below keeps its
  /// state. The lyrics take the whole of [height]; the stage only its own,
  /// so the controls below move down as the lyrics come ([_lyricsRoom]),
  /// instead of jumping.
  Widget _stageArea(
    (List<Track>, int)? stage,
    Track? track,
    double height,
    TextScaler textScaler,
  ) {
    final lyrics = _lyrics;
    final shown = _lyricsShown && lyrics != null;
    // Still there while they fade out.
    final mounted = lyrics != null && (_lyricsShown || _lyricsMix.value > 0);
    return AnimatedBuilder(
      animation: _lyricsRoom,
      builder: (context, child) => ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height * _lyricsRoom.value,
          maxHeight: height,
        ),
        child: child,
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // At opacity 0 nothing is painted: no blur of the lens below.
          NowPlayingStage(
            opacity: _stageOpacity,
            child: FadeTransition(
              opacity: _stageOpacity,
              child: IgnorePointer(
                ignoring: shown,
                child: ExcludeSemantics(
                  excluding: shown,
                  child: _stageOf(stage, track),
                ),
              ),
            ),
          ),
          if (mounted)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !shown,
                child: FadeTransition(
                  opacity: _lyricsIn,
                  child: SlideTransition(
                    position: _lyricsRise,
                    child: _fadeChrome(
                      BlocProvider.value(
                        value: lyrics,
                        // Content, not chrome: it follows the phone's font
                        // size past the page's cap.
                        child: MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaler: textScaler),
                          child: Column(
                            children: [
                              // Tinted by the glow behind, in step with it.
                              Expanded(
                                child:
                                    BlocBuilder<
                                      TrackPaletteCubit,
                                      TrackPaletteState
                                    >(
                                      builder: (_, palette) => PaletteInkScope(
                                        colorA: palette.backgroundColorA,
                                        colorB: palette.backgroundColorB,
                                        tone: DynamicBackgroundTone.immersive,
                                        child: const LyricsView(),
                                      ),
                                    ),
                              ),
                              MediaQuery.withClampedTextScaling(
                                maxScaleFactor: AppLayout.maxTextScale,
                                child: const PlayerProgressBar(),
                              ),
                              BlocSelector<PlayerBloc, PlayerState, bool>(
                                selector: (s) =>
                                    s is PlayerActive && s.isPlaying,
                                builder: (_, playing) => KeepScreenOn(
                                  active: shown && playing,
                                  child: const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
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

  /// The carousel, or a gap while the queue is not known yet.
  Widget _stageOf((List<Track>, int)? stage, Track? track) {
    if (stage case (final queue, final index)) {
      return ArtworkCarousel(
        queue: queue,
        currentIndex: index,
        onPageChanged: _onCarouselPageChanged,
        onFocusChanged: _onSwipeFocusChanged,
        enableHeroes: _heroes,
        lensOpacity: _stage,
        lensLift: _ringLift,
        neighbourOpacity: _dragFade,
        ringBuilder: (ring, hole) => _fade(
          _stage,
          ProgressRing(
            diameter: ring,
            holeDiameter: hole,
            lift: _ringLift,
            progress: context.read<PlayerBloc>().progress,
            onSeek: (position) =>
                context.read<PlayerBloc>().add(SeekRequested(position)),
          ),
        ),
      );
    }
    return SizedBox(height: track != null ? AppSpacing.xl2 : 0);
  }

  static Widget _fade(Animation<double>? opacity, Widget child) =>
      opacity == null ? child : FadeTransition(opacity: opacity, child: child);

  /// The page's last stretch of its route animation: where the tab bar
  /// goes down with the lyrics on the way in, and comes back first thing
  /// on the way out, so the surface still lands in a bar.
  static const _barGate = Interval(0.55, 1, curve: Curves.easeOut);

  /// [child] (the tab bar) moved [distance] down, off the screen, while
  /// the lyrics show: reading them, the tabs are of no use, and their room
  /// goes to the lines.
  Widget _lyricsAway({required double distance, required Widget child}) {
    final route = _chrome?.parent;
    return AnimatedBuilder(
      animation: Listenable.merge([_lyricsRoom, ?route]),
      child: child,
      builder: (_, child) {
        final gate = route == null ? 1.0 : _barGate.transform(route.value);
        return Transform.translate(
          offset: Offset(0, distance * _lyricsRoom.value * gate),
          child: child,
        );
      },
    );
  }

  /// Off the screen, the tab bar is not for a screen reader either: a tab
  /// it cannot show would still take a tap, and leave the page.
  Widget _unreadWithLyrics(Widget child) =>
      ExcludeSemantics(excluding: _lyricsShown, child: child);

  /// How far the lens is lifted under a finger on the ring (the ring
  /// writes it, the stage scales the lens with it).
  final _ringLift = ValueNotifier<double>(0);

  @override
  void dispose() {
    _likeBurst.dispose();
    unawaited(_lyrics?.close());
    _stageOut.dispose();
    _lyricsIn.dispose();
    _lyricsRoom.dispose();
    _lyricsMix.dispose();
    _publishCover(null, replacing: _cover);
    _chrome?.parent.removeStatusListener(_enableHeroesOnceShown);
    _chrome?.dispose();
    _backdrop?.dispose();
    _slotClosed?.dispose();
    _stage?.dispose();
    _cover?.dispose();
    _snapBack.dispose();
    _dragFade.dispose();
    _swipeFocus.dispose();
    _ringLift.dispose();
    super.dispose();
  }

  // ── Drag handlers ─────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    // Only track downward movement.
    final next = _dragOffset + d.delta.dy;
    if (next >= 0) setState(() => _setDragOffset(next));
  }

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond.dy;
    final screenH = MediaQuery.of(context).size.height;

    // A flick up opens the queue, the mirror of drag-to-dismiss.
    if (velocity < -_kQueueVelocity && _dragOffset == 0) {
      showQueueSheet(context);
      return;
    }

    if (velocity > _kDismissVelocity ||
        _dragOffset > screenH * _kDismissThreshold) {
      // Keep the dragged offset: the heroes measure their position with
      // transforms, so the ring morphs from where the finger left it.
      _dismissFullPlayer(context);
    } else {
      // Snap back to fully-open position.
      _snapAnim = Tween<double>(
        begin: _dragOffset,
        end: 0,
      ).animate(CurvedAnimation(parent: _snapBack, curve: Curves.easeOutCubic));
      _snapBack
        ..reset()
        ..forward();
    }
  }

  /// Everything the page layout depends on, excluding position and buffering.
  /// [Queue] equality short-circuits on identity, so this stays cheap on ticks.
  Object? _structuralKey(PlayerState state) => switch (state) {
    PlayerActive(:final currentTrack, :final queue) => (
      PlayerActive,
      currentTrack.id,
      queue,
    ),
    PlayerLoading(:final track) => (PlayerLoading, track.id),
    _ => state.runtimeType,
  };

  Track? _resolveTrack(PlayerState state) {
    switch (state) {
      case PlayerActive(:final currentTrack):
        _lastResolvedTrack = currentTrack;
        return currentTrack;
      case PlayerLoading(:final track):
        _lastResolvedTrack = track;
        return track;
      case PlayerIdle():
      case PlayerError():
        return _lastResolvedTrack;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    // The phone's own, before the page caps it for its chrome.
    final textScaler = MediaQuery.textScalerOf(context);
    // Bottom inset + nav bar (tabs only) + its 0.5 px glass border.
    final navBarReserve = safeBottom + 12 + AppSpacing.navBarHeight + 1;

    // The page uses both allowed blurs: what opens from it is opaque.
    return BlurBudgetSpent(
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            getIt<PlaybackSessionStore>().setFullPlayerOpen(false);
          }
        },
        child: GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: BlocListener<PlayerBloc, PlayerState>(
            listenWhen: (prev, curr) =>
                curr is PlayerActive &&
                (prev is! PlayerActive ||
                    prev.currentTrack != curr.currentTrack),
            listener: (context, state) {
              if (state is PlayerActive) {
                context.read<LikesCubit>().syncTrack(state.currentTrack);
              }
            },
            child: Scaffold(
              // The background below fades on its own (_backdrop).
              backgroundColor: Colors.transparent,
              // Laid out for the font size up to the layout cap.
              body: MediaQuery.withClampedTextScaling(
                maxScaleFactor: AppLayout.maxTextScale,
                child: BlocBuilder<PlayerBloc, PlayerState>(
                  // Position ticks must not rebuild the page: only the
                  // track, the queue or the state kind matter here.
                  buildWhen: (prev, curr) =>
                      _structuralKey(prev) != _structuralKey(curr),
                  builder: (context, state) {
                    final track = _resolveTrack(state);
                    final stage = _resolveStage(state);

                    return Stack(
                      children: [
                        // Dynamic background: it stays put while the
                        // content is dragged down.
                        _fade(
                          _backdrop,
                          ColoredBox(
                            color: context.colors.bgPrimary,
                            child:
                                BlocBuilder<
                                  TrackPaletteCubit,
                                  TrackPaletteState
                                >(
                                  builder: (_, palette) => DynamicBackground(
                                    colorA: palette.backgroundColorA,
                                    colorB: palette.backgroundColorB,
                                    tone: DynamicBackgroundTone.immersive,
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                          ),
                        ),

                        // Content: the only part a drag moves, as in
                        // the reference.
                        Transform.translate(
                          offset: Offset(0, _dragOffset),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              children: [
                                // Top bar: dismiss + options
                                _fadeChrome(
                                  _TopBar(
                                    likeBurst: _likeBurst,
                                    lyrics: _lyricsShown ? _lyrics : null,
                                  ),
                                ),

                                const SizedBox(height: AppSpacing.lg),

                                // Track info + like
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl2,
                                  ),
                                  child: _fadeChrome(
                                    // Only the title rebuilds as a swipe
                                    // crosses covers.
                                    ValueListenableBuilder<int?>(
                                      valueListenable: _swipeFocus,
                                      builder: (_, focus, _) {
                                        final focused =
                                            focus != null &&
                                            focus < _stageQueue.length;
                                        return _TrackInfo(
                                          track: focused
                                              ? _stageQueue[focus]
                                              : track,
                                          index: focused ? focus : stage?.$2,
                                          queueLength: _stageQueue.length,
                                          likeBurst: _likeBurst,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // No gap: the artist line's touch target
                                // already leaves room under the name.

                                // The stage takes what the controls leave, up
                                // to its full size: on a short screen the ring
                                // shrinks instead of pushing them off screen.
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, box) => Column(
                                      children: [
                                        _stageArea(
                                          stage,
                                          track,
                                          math.max(
                                            0,
                                            box.maxHeight - _kControlsBlock,
                                          ),
                                          textScaler,
                                        ),
                                        // Secondary controls (Glass Utility
                                        // Dock) and primary playback controls
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _fadeChrome(
                                                PlayerUtilityDock(
                                                  lyricsShown: _lyricsShown,
                                                  onLyricsTap: _toggleLyrics,
                                                ),
                                                glass: true,
                                              ),
                                              _fadeChrome(
                                                const PlayerControls(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Room for the nav bar overlaid below; with
                                // the lyrics the bar is away, and the
                                // controls take its place.
                                AnimatedBuilder(
                                  animation: _lyricsRoom,
                                  builder: (_, _) => SizedBox(
                                    height: lerpDouble(
                                      navBarReserve,
                                      safeBottom + AppSpacing.lg,
                                      _lyricsRoom.value,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Nav bar at bottom, mini player hidden. It goes
                        // with the background, uncovering the shell's
                        // own bar, which holds the mini player row the
                        // surface lands in; before that it opens an
                        // empty slot of that row's height (_slotClosed).
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _lyricsAway(
                            distance: navBarReserve + 8,
                            child: _unreadWithLyrics(
                              _fade(
                                _backdrop,
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    safeBottom + 12,
                                  ),
                                  child: AppBottomNavBar(
                                    currentTab: AppTab.player,
                                    showMiniPlayer: false,
                                    // Without the morph (opened at launch),
                                    // no surface leaves the bar: it stays
                                    // shut until the page can be dismissed.
                                    miniSlot: _heroes
                                        ? _slot
                                        : kAlwaysDismissedAnimation,
                                    onTabChanged: (tab) {
                                      switch (tab) {
                                        case AppTab.home:
                                          _leaveFullPlayerTo(context, '/home');
                                        case AppTab.library:
                                          _leaveFullPlayerTo(
                                            context,
                                            '/library',
                                          );
                                        case AppTab.search:
                                          _leaveFullPlayerTo(
                                            context,
                                            '/search',
                                          );
                                        case AppTab.playlists:
                                          _leaveFullPlayerTo(
                                            context,
                                            '/playlists',
                                          );
                                        case AppTab.player:
                                          // The orb closes the page it opened.
                                          _dismissFullPlayer(context);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final LikeBurstController likeBurst;

  /// The lyrics on screen, if any: the song's menu then leads with theirs.
  final LyricsCubit? lyrics;

  const _TopBar({required this.likeBurst, required this.lyrics});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: context.l10n.playerClose,
            onTap: () => _dismissFullPlayer(context),
            excludeSemantics: true,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _dismissFullPlayer(context),
              child: const Icon(
                AppIcons.minimize,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: context.l10n.detailMore,
            onTap: () => _showOptionsSheet(context),
            excludeSemantics: true,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(40),
              onPressed: () => _showOptionsSheet(context),
              child: const Icon(
                AppIcons.moreVertical,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    final state = context.read<PlayerBloc>().state;
    if (state is! PlayerActive) return;

    final lyrics = this.lyrics;
    showTrackActions(
      context,
      state.currentTrack,
      origin: TrackActionOrigin.nowPlaying,
      onLikeToggled: (liked) => likeBurst.play(liked: liked),
      // With lyrics on screen, their own menu comes first: import, search
      // again, timing, remove.
      first: [
        if (lyrics != null && lyrics.state is LyricsShown)
          SheetAction(
            label: context.l10n.lyricsOptions,
            icon: AppIcons.lyricsOptions,
            onPressed: () => showLyricsOptions(context, lyrics),
          ),
      ],
    );
  }
}

void _dismissFullPlayer(BuildContext context) {
  final router = GoRouter.of(context);
  getIt<PlaybackSessionStore>().setFullPlayerOpen(false);
  if (router.canPop()) {
    context.pop();
    return;
  }
  context.go('/home');
}

void _leaveFullPlayerTo(BuildContext context, String location) {
  getIt<PlaybackSessionStore>().setFullPlayerOpen(false);
  context.go(location);
}

// ─────────────────────────────────────────────────────────────────────────────

class _TrackInfo extends StatelessWidget {
  final Track? track;
  final int? index;
  final int queueLength;
  final LikeBurstController likeBurst;

  const _TrackInfo({
    required this.track,
    required this.index,
    required this.queueLength,
    required this.likeBurst,
  });

  @override
  Widget build(BuildContext context) {
    final track = this.track;
    return Row(
      children: [
        Expanded(
          child: TrackTitleSwitcher(
            track: track,
            index: index,
            queueLength: queueLength,
            onArtistTap: (track) => openArtistOf(
              context,
              track,
              origin: TrackActionOrigin.nowPlaying,
            ),
          ),
        ),
        BlocBuilder<LikesCubit, LikesState>(
          builder: (context, state) {
            final isLiked = state.isLiked && state.id == track?.id;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                AppIconButton(
                  icon: isLiked ? AppIcons.liked : AppIcons.like,
                  tooltip: isLiked
                      ? context.l10n.likesRemove
                      : context.l10n.trackLike,
                  size: 26,
                  // Accent, like the liked songs playlist it adds to.
                  color: isLiked ? context.colors.accent : Colors.white70,
                  onPressed: () {
                    if (track == null) return;
                    context.read<LikesCubit>().toggle(track);
                    // A like answers alike everywhere: a light tick and
                    // the heart popping, as on the mini player.
                    AppHaptics.lightImpact();
                    likeBurst.play(liked: !isLiked);
                  },
                ),
                Positioned.fill(
                  child: LikeBurst(controller: likeBurst, size: 40),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
