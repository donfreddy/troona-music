import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/widgets/glass_lens.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';
import 'package:troona/shared/widgets/artwork_image.dart';

/// Now Playing stage: circular covers sliding under a fixed [GlassLens].
///
/// Layers, bottom to top:
/// 1. covers, positioned and scaled from the page offset (paint only),
/// 2. the lens, a single clipped [BackdropFilter] that never moves,
/// 3. a transparent [PageView] that only provides gestures and physics.
///
/// Geometry is proportional to the width, measured on the reference design.
/// A bounded height shrinks the whole stage so the ring fits it: short
/// screens (16:9, a large font) keep the controls below on screen.
class ArtworkCarousel extends StatefulWidget {
  final List<Track> queue;
  final int currentIndex;

  /// Called once a user swipe has settled on another track: never
  /// mid-gesture, never for programmatic scrolls or interrupted animations.
  final ValueChanged<int> onPageChanged;

  /// The page a user swipe is heading to, as soon as it is the nearest to
  /// the centre (so the title can change during the swipe, not after it);
  /// null once the carousel follows the playing track again. Called only
  /// when the value changes.
  final ValueChanged<int?>? onFocusChanged;

  /// Optional layer laid over the lens and the gesture layer, sized to the
  /// ring (the progress ring). It must restrict its own hit testing so
  /// swipes outside it still reach the carousel.
  final Widget Function(double ringDiameter, double holeDiameter)? ringBuilder;

  /// Tags the ring area and the current cover as [NowPlayingHero] elements,
  /// so they morph to and from the mini player. Only one stage per route may
  /// enable it.
  final bool enableHeroes;

  /// Opacity of the glass lens. With [enableHeroes] the lens itself does not
  /// fly (the surface hero is an invisible box under the covers), so the
  /// route fades it while the shuttle morphs over it.
  final Animation<double>? lensOpacity;

  /// How far the lens is lifted under the finger, 0 to 1 (eased), as the
  /// progress ring reports it: the lens and the current cover grow by
  /// [GlassLens.liftScale], the neighbours stay as they are.
  final ValueListenable<double>? lensLift;

  /// Opacity of the covers beside the current one (the page fades them
  /// with its chrome while dragged down).
  final Animation<double>? neighbourOpacity;

  const ArtworkCarousel({
    super.key,
    required this.queue,
    required this.currentIndex,
    required this.onPageChanged,
    this.onFocusChanged,
    this.ringBuilder,
    this.enableHeroes = false,
    this.lensOpacity,
    this.lensLift,
    this.neighbourOpacity,
  });

  @override
  State<ArtworkCarousel> createState() => _ArtworkCarouselState();
}

// Proportions of the stage width, sampled from the reference screenshots.
const double _kRingFraction = 0.80;
const double _kArtFraction = 0.50;

/// Centre-to-centre distance. With [_kNeighbourScale], a neighbour sits
/// astride the lens rim and runs a little past the screen's edge, which
/// cuts about a quarter of it (screenshots/inspire.png: centres 0.42 of
/// the width apart, a neighbour 0.31 of the width across).
const double _kSpacingFraction = 0.42;
const double _kNeighbourScale = 0.64;

/// How much the cover under a finger shrinks into the hole (the reference
/// goes to 0.78), leaving the dark well around it: the stage answers the
/// touch before any swipe.
const double _kPressShrink = 0.22;

/// The reference's 200 ms in, fast at first; out as the swipe settles.
const Duration _kPressIn = Duration(milliseconds: 200);
const Duration _kPressOut = Duration(milliseconds: 240);

/// How long the cover takes to sink when the player changes the song by
/// itself: it is down within the first third of the sweep, and back up
/// ([_kPressOut]) a little after the sweep lands.
const Duration _kDipIn = Duration(milliseconds: 100);

/// The floor of the hole, seen around a pressed cover and between two
/// covers during a swipe.
const Color _kWell = Color(0x73000000);

/// Below this ring (split screen, a floating window) the stage is left out:
/// a ring the size of a button shows nothing and its lens degenerates.
const double _kMinRing = 120;

/// Snappy, as in the reference (2 to 3 frames at 10 fps).
const Duration _kSkipDuration = Duration(milliseconds: 260);

/// How long to wait for the bloc to confirm a swipe before snapping back.
const Duration _kSwipeConfirmTimeout = Duration(milliseconds: 800);

class _ArtworkCarouselState extends State<ArtworkCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _pageCtrl;

  /// 1 while a finger holds the cover in the hole, 0 at rest.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: _kPressIn,
    reverseDuration: _kPressOut,
  );

  /// Fast at first both ways: an ease-out played backwards would end the
  /// release at full speed.
  late final Animation<double> _pressed = CurvedAnimation(
    parent: _press,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  /// Whether a finger holds the cover down right now.
  bool _fingerOnCover = false;

  /// A finger down on the hole (the ring band answers its own touches).
  void _onPointerDown(PointerDownEvent event, Offset center, double hole) {
    if ((event.localPosition - center).distance > hole / 2) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _fingerOnCover = true;
    _press.forward();
  }

  void _onPointerGone(PointerEvent _) {
    _fingerOnCover = false;
    _press.reverse();
  }

  /// A change the player made (a button, the end of a song) moves like a
  /// swipe: the cover sinks into the hole as it leaves, and the one that
  /// comes grows as it lands. No hold first, as under a finger: a button
  /// must answer at once.
  void _dip() {
    if (_fingerOnCover || MediaQuery.disableAnimationsOf(context)) return;
    _press.animateTo(1, duration: _kDipIn).whenCompleteOrCancel(() {
      if (mounted && !_fingerOnCover) _press.reverse();
    });
  }

  /// Page under the finger when the current drag started; null when the
  /// ongoing scroll (if any) was not started by the user.
  int? _dragStartPage;
  Timer? _confirmTimer;

  /// Set while a jump to a new queue waits for the PageView to rebuild with
  /// the new item count. Jumping earlier would clamp to the old extent.
  bool _jumpPending = false;

  /// The queue changed while the user was scrolling: whatever page they
  /// land on now refers to other tracks, so the scroll end must not report
  /// it, and must jump (not sweep) to the bloc index instead.
  bool _queueChangedDuringScroll = false;

  /// Last value sent to [ArtworkCarousel.onFocusChanged].
  int? _focus;

  /// The stage is left out (too little room): the PageView is gone, so
  /// track changes meanwhile are caught up once it is back.
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(
      initialPage: widget.currentIndex,
      viewportFraction: _kSpacingFraction,
    )..addListener(_trackFocus);
  }

  /// Only user swipes (drag and the settle after it) report a focus:
  /// programmatic sweeps pass through tracks that are not being chosen.
  void _trackFocus() {
    if (_dragStartPage == null || _queueChangedDuringScroll) return;
    final page = _pageCtrl.page;
    if (page == null) return;
    final nearest = page.round();
    if (nearest < 0 || nearest >= widget.queue.length) return;
    _setFocus(
      nearest == widget.currentIndex && _focus == null ? null : nearest,
    );
  }

  void _setFocus(int? page) {
    if (page == _focus) return;
    _focus = page;
    widget.onFocusChanged?.call(page);
  }

  @override
  void didUpdateWidget(ArtworkCarousel old) {
    super.didUpdateWidget(old);
    if (!_pageCtrl.hasClients) return;

    // Shuffle, removal, reorder or restore: the pages now hold other
    // tracks, so sweeping through them would show unrelated covers. Jump,
    // once the PageView has been rebuilt with the new item count.
    if (!listEquals(old.queue, widget.queue)) {
      _setFocus(null);
      if (_dragStartPage != null) {
        _queueChangedDuringScroll = true;
      } else {
        _scheduleJump();
      }
      return;
    }
    if (old.currentIndex != widget.currentIndex) {
      // The bloc moved (swipe confirmed, or anything else): its track is
      // the title again.
      if (_dragStartPage == null) _setFocus(null);
      _syncToBloc();
    }
  }

  @override
  void dispose() {
    _confirmTimer?.cancel();
    _pageCtrl.dispose();
    _press.dispose();
    super.dispose();
  }

  void _scheduleJump() {
    _jumpPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpPending = false;
      if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(widget.currentIndex);
    });
  }

  /// Follows the bloc (skip buttons, queue taps, track end), unless the user
  /// is dragging: stealing the gesture would freeze the finger. In that case
  /// the scroll end handler reconciles.
  void _syncToBloc() {
    if (!mounted || !_pageCtrl.hasClients || _dragStartPage != null) return;
    _setFocus(null);
    if (_pageCtrl.page?.round() == widget.currentIndex) return;
    _dip();
    _pageCtrl.animateToPage(
      widget.currentIndex,
      duration: _kSkipDuration,
      curve: Curves.easeOutCubic,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _dragStartPage ??= _pageCtrl.page?.round();
    }
    if (notification is! ScrollEndNotification || !_pageCtrl.hasClients) {
      return false;
    }

    final page = _pageCtrl.page;
    if (page == null) return false;
    final settled = page.round();
    // A tap during an animation ends the scroll mid-page; the ballistic
    // settle that follows emits its own end notification.
    if ((page - settled).abs() > 0.01) return false;

    final startPage = _dragStartPage;
    _dragStartPage = null;
    if (_queueChangedDuringScroll) {
      _queueChangedDuringScroll = false;
      if (settled != widget.currentIndex) _scheduleJump();
      return false;
    }
    if (settled == widget.currentIndex) {
      _setFocus(null);
      return false;
    }

    if (startPage != null && settled != startPage) {
      widget.onPageChanged(settled);
      // If the bloc ignores the swipe, do not leave a stale cover centred.
      _confirmTimer?.cancel();
      _confirmTimer = Timer(_kSwipeConfirmTimeout, _syncToBloc);
    } else {
      // Interrupted programmatic scroll, or a drag released where it began
      // while the bloc moved on: realign with the playing track. Deferred:
      // the ending activity would otherwise reset the scroll to idle.
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncToBloc());
    }
    return false;
  }

  double get _page {
    if (_jumpPending) return widget.currentIndex.toDouble();
    if (_pageCtrl.hasClients && _pageCtrl.position.haveDimensions) {
      return _pageCtrl.page ?? widget.currentIndex.toDouble();
    }
    return widget.currentIndex.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : context.screenWidth;
        // The width the proportions apply to: the full width, unless the
        // height cannot hold the ring it gives.
        final stage = constraints.maxHeight.isFinite
            ? math.min(width, (constraints.maxHeight - 8) / _kRingFraction)
            : width;
        final ringSize = stage * _kRingFraction;
        if (ringSize < _kMinRing) {
          _hidden = true;
          return const SizedBox.shrink();
        }
        if (_hidden) {
          // Reattached on its last page: jump to the playing track.
          _hidden = false;
          _scheduleJump();
        }
        final artSize = stage * _kArtFraction;
        final spacing = stage * _kSpacingFraction;
        // Artwork is extracted as square JPEGs, so constraining the width is
        // enough for a sharp BoxFit.cover.
        final cacheWidth = math.max(
          1,
          (artSize * MediaQuery.devicePixelRatioOf(context)).round(),
        );

        final lens = GlassLens(diameter: ringSize, holeDiameter: artSize);

        return SizedBox(
          width: width,
          height: ringSize + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Heroes fly in tree order, later ones on top: the surface must
              // come before the covers so the morphing disc never hides the
              // artwork shuttle.
              HeroMode(
                enabled: widget.enableHeroes,
                child: Hero(
                  tag: NowPlayingHero.surfaceTag,
                  createRectTween: NowPlayingHero.flightTween,
                  flightShuttleBuilder: NowPlayingHero.surfaceShuttle,
                  child: SizedBox.square(dimension: ringSize),
                ),
              ),
              // Scroll frames repaint only the covers, not the whole page.
              // They fade with the lens: on dismiss the neighbours are gone
              // before the surface lands, instead of staying while it
              // leaves. The current cover is hidden while it flies, so
              // this only shows when no flight takes it (no mini player
              // cover, heroes off at launch).
              _fade(
                widget.lensOpacity,
                RepaintBoundary(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pageCtrl, _pressed]),
                      builder: (_, _) => _buildCovers(
                        page: _page,
                        artSize: artSize,
                        spacing: spacing,
                        cacheWidth: cacheWidth,
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: _fade(widget.lensOpacity, _lift(widget.lensLift, lens)),
              ),
              Listener(
                onPointerDown: (event) => _onPointerDown(
                  event,
                  Offset(width / 2, (ringSize + 8) / 2),
                  artSize,
                ),
                onPointerUp: _onPointerGone,
                onPointerCancel: _onPointerGone,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: PageView.builder(
                    controller: _pageCtrl,
                    physics: const _SnapSpring(),
                    itemCount: widget.queue.length,
                    itemBuilder: (_, _) => const SizedBox.expand(),
                  ),
                ),
              ),
              if (widget.ringBuilder case final builder?)
                builder(ringSize, artSize),
            ],
          ),
        );
      },
    );
  }

  /// Paints the covers around [page], farthest first so the centre wins.
  Widget _buildCovers({
    required double page,
    required double artSize,
    required double spacing,
    required int cacheWidth,
  }) {
    final queue = widget.queue;
    if (queue.isEmpty) return const SizedBox.shrink();

    final first = (page.floor() - 1).clamp(0, queue.length - 1);
    final last = (page.ceil() + 1).clamp(0, queue.length - 1);
    final indices = [for (var i = first; i <= last; i++) i]
      ..sort((a, b) => (b - page).abs().compareTo((a - page).abs()));

    return Stack(
      alignment: Alignment.center,
      // Neighbours are translated outside this stack's own bounds.
      clipBehavior: Clip.none,
      children: [
        // Hidden by the cover that fills the hole, at rest.
        DecoratedBox(
          key: const ValueKey('well'),
          decoration: const BoxDecoration(
            color: _kWell,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: artSize),
        ),
        // Keyed by queue index (track ids may repeat in a queue) so the
        // elements survive the z-order changes during a swipe.
        for (final index in indices)
          KeyedSubtree(
            key: ValueKey(index),
            child: _positioned(
              delta: index - page,
              spacing: spacing,
              // The current cover grows with the lens: it fills the hole,
              // and a fixed one would leave a ring of bare background
              // between it and the lit band.
              // Every disc keeps the same wrapper, so a track change does
              // not recreate its image.
              child: FadeTransition(
                opacity: index == widget.currentIndex
                    ? kAlwaysCompleteAnimation
                    : widget.neighbourOpacity ?? kAlwaysCompleteAnimation,
                child: _LiftScale(
                  lift: widget.lensLift,
                  enabled: index == widget.currentIndex,
                  child: _Disc(
                    track: queue[index],
                    size: artSize,
                    cacheWidth: cacheWidth,
                    isHero: widget.enableHeroes && index == widget.currentIndex,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _fade(Animation<double>? opacity, Widget child) =>
      opacity == null ? child : FadeTransition(opacity: opacity, child: child);

  /// Rebuilds only while the lift moves (a press on the ring), never on
  /// position ticks; [child] is built once.
  static Widget _lift(ValueListenable<double>? lift, Widget child) =>
      lift == null
      ? child
      : ValueListenableBuilder<double>(
          valueListenable: lift,
          child: child,
          builder: (_, value, child) => Transform.scale(
            scale: 1 + GlassLens.liftScale * value,
            child: child,
          ),
        );

  Widget _positioned({
    required double delta,
    required double spacing,
    required Widget child,
  }) {
    final distance = delta.abs().clamp(0.0, 1.0);
    // The press takes the cover in the hole only: less of it the further
    // a cover is from the centre, none of it on the neighbours.
    final scale =
        (1 - (1 - _kNeighbourScale) * distance) *
        (1 - _kPressShrink * _pressed.value * (1 - distance));
    return Transform.translate(
      offset: Offset(delta * spacing, 0),
      child: Transform.scale(scale: scale, child: child),
    );
  }
}

/// The snap of a released swipe, stiffer than the default spring: the
/// cover is in the hole within about a quarter of a second, as in the
/// reference. The default takes over half a second, and the track only
/// changes once the page has settled.
class _SnapSpring extends ScrollPhysics {
  const _SnapSpring({super.parent});

  @override
  _SnapSpring applyTo(ScrollPhysics? ancestor) =>
      _SnapSpring(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: 0.5, stiffness: 400, ratio: 1.1);
}

/// Scales [child] by the lens lift when [enabled]; the same structure
/// either way.
class _LiftScale extends StatelessWidget {
  final ValueListenable<double>? lift;
  final bool enabled;
  final Widget child;

  const _LiftScale({
    required this.lift,
    required this.enabled,
    required this.child,
  });

  static const _still = AlwaysStoppedAnimation<double>(0);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: lift ?? _still,
    child: child,
    builder: (_, value, child) => Transform.scale(
      scale: enabled ? 1 + GlassLens.liftScale * value : 1,
      child: child,
    ),
  );
}

class _Disc extends StatelessWidget {
  final Track track;
  final double size;
  final int cacheWidth;

  /// When set, the unclipped image flies as a hero; the circle clip stays
  /// outside so the shuttle controls the in-flight shape.
  /// Every disc keeps its [Hero] so toggling the current one does not
  /// recreate the image element; [HeroMode] picks the one that flies.
  final bool isHero;

  const _Disc({
    required this.track,
    required this.size,
    required this.cacheWidth,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final path = track.artworkPath;
    final Widget image = path != null
        ? Image.file(
            File(path),
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const ArtworkPlaceholder(),
          )
        : const ArtworkPlaceholder();
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: HeroMode(
          enabled: isHero,
          child: Hero(
            tag: NowPlayingHero.artworkTag,
            createRectTween: NowPlayingHero.flightTween,
            flightShuttleBuilder: NowPlayingHero.artworkShuttle,
            child: image,
          ),
        ),
      ),
    );
  }
}
