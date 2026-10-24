import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/extensions/context_ext.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/presentation/widgets/glass_lens.dart';

/// Now Playing stage: circular covers sliding under a fixed [GlassLens].
///
/// Layers, bottom to top:
/// 1. covers, positioned and scaled from the page offset (paint only),
/// 2. the lens, a single clipped [BackdropFilter] that never moves,
/// 3. a transparent [PageView] that only provides gestures and physics.
///
/// Geometry is proportional to the width, measured on the reference design.
class ArtworkCarousel extends StatefulWidget {
  final List<Track> queue;
  final int currentIndex;

  /// Called once a user swipe has settled on another track: never
  /// mid-gesture, never for programmatic scrolls or interrupted animations.
  final ValueChanged<int> onPageChanged;

  /// Optional layer laid over the lens and the gesture layer, sized to the
  /// ring (the progress ring). It must restrict its own hit testing so
  /// swipes outside it still reach the carousel.
  final Widget Function(double ringDiameter, double holeDiameter)? ringBuilder;

  const ArtworkCarousel({
    super.key,
    required this.queue,
    required this.currentIndex,
    required this.onPageChanged,
    this.ringBuilder,
  });

  @override
  State<ArtworkCarousel> createState() => _ArtworkCarouselState();
}

// Proportions of the stage width, sampled from the reference screenshots.
const double _kRingFraction = 0.80;
const double _kArtFraction = 0.50;
const double _kSpacingFraction = 0.42; // centre-to-centre distance
const double _kNeighbourScale = 0.64;

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

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(
      initialPage: widget.currentIndex,
      viewportFraction: _kSpacingFraction,
    );
  }

  @override
  void didUpdateWidget(ArtworkCarousel old) {
    super.didUpdateWidget(old);
    if (!_pageCtrl.hasClients) return;

    // Shuffle, removal, reorder or restore: the pages now hold other
    // tracks, so sweeping through them would show unrelated covers. Jump,
    // once the PageView has been rebuilt with the new item count.
    if (!listEquals(old.queue, widget.queue)) {
      if (_dragStartPage != null) {
        _queueChangedDuringScroll = true;
      } else {
        _scheduleJump();
      }
      return;
    }
    if (old.currentIndex != widget.currentIndex) _syncToBloc();
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
    if (settled == widget.currentIndex) return false;

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
        final ringSize = width * _kRingFraction;
        final artSize = width * _kArtFraction;
        final spacing = width * _kSpacingFraction;
        // Artwork is extracted as square JPEGs, so constraining the width is
        // enough for a sharp BoxFit.cover.
        final cacheWidth = math.max(
          1,
          (artSize * MediaQuery.devicePixelRatioOf(context)).round(),
        );

        return SizedBox(
          width: width,
          height: ringSize + 8,
          child: Stack(
            alignment: Alignment.center,
            children: [
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
              IgnorePointer(
                child: GlassLens(diameter: ringSize, holeDiameter: artSize),
              ),
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
              ),
            ),
          ),
      ],
    );
  }

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

  const _Disc({
    required this.track,
    required this.size,
    required this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final path = track.artworkPath;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: path != null
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const _ArtworkPlaceholder(),
              )
            : const _ArtworkPlaceholder(),
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
