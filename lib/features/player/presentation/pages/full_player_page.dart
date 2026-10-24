import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/semantic/app_spacing.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/artwork_carousel.dart';
import 'package:troona/features/player/presentation/widgets/player_controls.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/features/player/presentation/widgets/progress_ring.dart';
import 'package:troona/features/player/presentation/widgets/queue_sheet.dart';
import 'package:troona/features/player/presentation/widgets/track_title_switcher.dart';
import 'package:troona/features/playlist/presentation/widgets/add_to_playlist_sheet.dart';
import 'package:troona/shared/widgets/app_bottom_nav_bar.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

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

class _FullPlayerPageState extends State<FullPlayerPage>
    with SingleTickerProviderStateMixin {
  // ── Drag-to-dismiss state ─────────────────────────────────────────────────
  late final AnimationController _snapBack;
  late Animation<double> _snapAnim;
  double _dragOffset = 0;
  Track? _lastResolvedTrack;

  /// Last queue shown by the carousel, kept while the next track loads so
  /// the stage is not unmounted (and its scroll state lost) on every swipe.
  List<Track> _stageQueue = const [];
  int _stageIndex = 0;

  /// Index the user swiped to, used to disambiguate duplicate tracks while
  /// the requested track loads.
  int? _requestedStageIndex;

  /// Stage page a swipe is heading to: the title shows its track during
  /// the swipe instead of waiting for the bloc. Null otherwise.
  final _swipeFocus = ValueNotifier<int?>(null);

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
          setState(() => _dragOffset = _snapAnim.value);
        });

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

  /// Chrome (top bar, title, controls) fades on the last half of the route
  /// animation: on dismiss it is gone before the ring finishes its morph
  /// into the mini player, as in the reference.
  CurvedAnimation? _chrome;

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
      _stage?.dispose();
      _cover?.dispose();
      _chrome = CurvedAnimation(
        parent: routeAnimation,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
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

  Widget _fadeChrome(Widget child) => _fade(_chrome, child);

  static Widget _fade(Animation<double>? opacity, Widget child) =>
      opacity == null ? child : FadeTransition(opacity: opacity, child: child);

  @override
  void dispose() {
    _publishCover(null, replacing: _cover);
    _chrome?.parent.removeStatusListener(_enableHeroesOnceShown);
    _chrome?.dispose();
    _stage?.dispose();
    _cover?.dispose();
    _snapBack.dispose();
    _swipeFocus.dispose();
    super.dispose();
  }

  // ── Drag handlers ─────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    // Only track downward movement.
    final next = _dragOffset + d.delta.dy;
    if (next >= 0) setState(() => _dragOffset = next);
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
    // Bottom inset + nav bar (tabs only) + its 0.5 px glass border.
    final navBarReserve = safeBottom + 12 + AppSpacing.navBarHeight + 1;
    final screenH = MediaQuery.of(context).size.height;

    // Fade the page out slightly as the user drags down.
    final opacity =
        1.0 - (_dragOffset / screenH).clamp(0.0, _kMaxOpacityReduction);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          getIt<PlaybackSessionStore>().setFullPlayerOpen(false);
        }
      },
      child: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Opacity(
            opacity: opacity,
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
                //backgroundColor: Colors.black,
                body: BlocBuilder<PlayerBloc, PlayerState>(
                  // Position ticks must not rebuild the page: only the
                  // track, the queue or the state kind matter here.
                  buildWhen: (prev, curr) =>
                      _structuralKey(prev) != _structuralKey(curr),
                  builder: (context, state) {
                    final track = _resolveTrack(state);
                    final stage = _resolveStage(state);

                    return Stack(
                      children: [
                        // Dynamic background
                        DynamicBackground(
                          artworkPath: track?.artworkPath,
                          tone: DynamicBackgroundTone.immersive,
                          child: const SizedBox.expand(),
                        ),

                        // Scrollable content
                        SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              // Top bar: dismiss + drag indicator + options
                              _fadeChrome(_TopBar()),

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
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: AppSpacing.lg),

                              // Artwork carousel
                              if (stage case (final queue, final index))
                                ArtworkCarousel(
                                  queue: queue,
                                  currentIndex: index,
                                  onPageChanged: _onCarouselPageChanged,
                                  onFocusChanged: (page) =>
                                      _swipeFocus.value = page,
                                  enableHeroes: _heroes,
                                  lensOpacity: _stage,
                                  ringBuilder: (ring, hole) => _fade(
                                    _stage,
                                    ProgressRing(
                                      diameter: ring,
                                      holeDiameter: hole,
                                      progress: context
                                          .read<PlayerBloc>()
                                          .progress,
                                      onSeek: (position) => context
                                          .read<PlayerBloc>()
                                          .add(SeekRequested(position)),
                                    ),
                                  ),
                                )
                              else if (track != null)
                                const SizedBox(height: AppSpacing.xl2),

                              // Playback controls, centred between the ring
                              // and the nav bar.
                              Expanded(
                                child: Center(
                                  child: _fadeChrome(const PlayerControls()),
                                ),
                              ),

                              // Room for the nav bar overlaid below.
                              SizedBox(height: navBarReserve),
                            ],
                          ),
                        ),

                        // Nav bar at bottom, mini player hidden
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              0,
                              12,
                              safeBottom + 12,
                            ),
                            child: AppBottomNavBar(
                              currentTab: AppTab.player,
                              showMiniPlayer: false,
                              onTabChanged: (tab) {
                                switch (tab) {
                                  case AppTab.home:
                                    _leaveFullPlayerTo(context, '/home');
                                  case AppTab.library:
                                    _leaveFullPlayerTo(context, '/library');
                                  case AppTab.search:
                                    _leaveFullPlayerTo(context, '/search');
                                  case AppTab.playlists:
                                    _leaveFullPlayerTo(context, '/playlists');
                                  case AppTab.player:
                                    break;
                                }
                              },
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Drag indicator pill, centred whatever the buttons on each side.
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _dismissFullPlayer(context),
                child: const Icon(
                  EvaIcons.chevronDown,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(40),
                onPressed: () => showQueueSheet(context),
                child: const Icon(
                  LucideIcons.listMusic,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(40),
                onPressed: () => _showOptionsSheet(context),
                child: const Icon(
                  EvaIcons.moreVertical,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    final state = context.read<PlayerBloc>().state;
    if (state is! PlayerActive) return;

    final isLiked = context
        .read<LikesCubit>()
        .state
        .isTrackLiked(state.currentTrack.id);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(state.currentTrack.title),
        message: Text(state.currentTrack.artist),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              context.read<LikesCubit>().toggle(state.currentTrack);
            },
            child: Text(
              isLiked ? 'Retirer des Titres likés' : 'Ajouter aux Titres likés',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              showAddToPlaylistSheet(context, state.currentTrack);
            },
            child: const Text('Ajouter à une playlist…'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ),
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

  const _TrackInfo({
    required this.track,
    required this.index,
    required this.queueLength,
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
          ),
        ),
        BlocBuilder<LikesCubit, LikesState>(
          builder: (context, state) {
            final isLiked = state.isLiked && state.id == track?.id;
            return IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.read<LikesCubit>().toggle(track),
              icon: Icon(
                isLiked ? EvaIcons.heart : EvaIcons.heartOutline,
                color: isLiked ? Colors.redAccent : Colors.white70,
                size: 26,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// ignore: unused_element
class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.volume_mute, color: Colors.white38, size: 16),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white60,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(value: 0.7, onChanged: (_) {}),
          ),
        ),
        const Icon(CupertinoIcons.volume_up, color: Colors.white38, size: 16),
      ],
    );
  }
}
