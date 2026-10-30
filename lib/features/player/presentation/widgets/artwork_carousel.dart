import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/widgets/glass_lens.dart';
import 'package:troona/features/player/presentation/widgets/now_playing_hero.dart';

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

  const ArtworkCarousel({
    super.key,
    required this.queue,
    required this.currentIndex,
    required this.onPageChanged,
    this.onFocusChanged,
    this.ringBuilder,
    this.enableHeroes = false,
    this.lensOpacity,
  });

  @override
  State<ArtworkCarousel> createState() => _ArtworkCarouselState();
}

// Proportions of the stage width, sampled from the reference screenshots.
const double _kRingFraction = 0.80;
const double _kArtFraction = 0.50;
const double _kSpacingFraction = 0.42; // centre-to-centre distance
const double _kNeighbourScale = 0.64;

/// Below this ring (split screen, a floating window) the stage is left out:
/// a ring the size of a button shows nothing and its lens degenerates.
const double _kMinRing = 120;

/// Snappy, as in the reference (2 to 3 frames at 10 fps).
const Duration _kSkipDuration = Duration(milliseconds: 260);

/// How long to wait for the bloc to confirm a swipe before snapping back.
const Duration _kSwipeConfirmTimeout = Duration(milliseconds: 800);

class _ArtworkCarouselState extends State<ArtworkCarousel> {
  late final PageController _pageCtrl;

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
                  flightShuttleBuilder: NowPlayingHero.surfaceShuttle,
                  child: SizedBox.square(dimension: ringSize),
                ),
              ),
              // Scroll frames repaint only the covers, not the whole page.
              RepaintBoundary(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pageCtrl,
                    builder: (_, _) => _buildCovers(
                      page: _page,
                      artSize: artSize,
                      spacing: spacing,
                      cacheWidth: cacheWidth,
                    ),
                  ),
                ),
              ),
              IgnorePointer(child: _fade(widget.lensOpacity, lens)),
              NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: widget.queue.length,
                  itemBuilder: (_, _) => const SizedBox.expand(),
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
        // Keyed by queue index (track ids may repeat in a queue) so the
        // elements survive the z-order changes during a swipe.
        for (final index in indices)
          KeyedSubtree(
            key: ValueKey(index),
            child: _positioned(
              delta: index - page,
              spacing: spacing,
              child: _Disc(
                track: queue[index],
                size: artSize,
                cacheWidth: cacheWidth,
                isHero: widget.enableHeroes && index == widget.currentIndex,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _fade(Animation<double>? opacity, Widget child) =>
      opacity == null ? child : FadeTransition(opacity: opacity, child: child);

  Widget _positioned({
    required double delta,
    required double spacing,
    required Widget child,
  }) {
    final distance = delta.abs().clamp(0.0, 1.0);
    final scale = 1 - (1 - _kNeighbourScale) * distance;
    return Transform.translate(
      offset: Offset(delta * spacing, 0),
      child: Transform.scale(scale: scale, child: child),
    );
  }
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
            errorBuilder: (_, _, _) => const _ArtworkPlaceholder(),
          )
        : const _ArtworkPlaceholder();
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: HeroMode(
          enabled: isHero,
          child: Hero(
            tag: NowPlayingHero.artworkTag,
            flightShuttleBuilder: NowPlayingHero.artworkShuttle,
            child: image,
          ),
        ),
      ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: .08),
      child: const Center(
        child: Icon(CupertinoIcons.music_note, size: 64, color: Colors.white30),
      ),
    );
  }
}
