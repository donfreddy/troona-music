import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared-element morph between the mini player and the Now Playing stage.
///
/// Two heroes fly together on open and dismiss:
/// - [surfaceTag]: the ring area of the stage and the mini player body.
///   The rect tween turns the square ring into the wide row; the shuttle
///   lerps the corner radius, so the circle becomes a squircle, then a pill.
/// - [artworkTag]: the round cover and the rounded thumbnail.
///
/// Both sides clip *outside* their [Hero] and pass an unclipped child, so the
/// shuttle alone decides the in-flight shape. Nested heroes are not allowed:
/// the surface hero must be a sibling of the row content, never its parent.
///
/// Shuttles stack in the tree order of the route being left, so both sides
/// declare the surface hero before the artwork hero.
abstract final class NowPlayingHero {
  static const surfaceTag = 'now-playing-surface';
  static const artworkTag = 'now-playing-artwork';

  /// Corner radius of the mini player row (both ends of the morph).
  static const double miniSurfaceRadius = 24;

  /// Corner radius of the mini player thumbnail.
  static const double miniArtworkRadius = 16;

  /// Straight flight for every Now Playing hero. Both ends of the surface
  /// and of the artwork share a vertical centre (ring and cover, row and
  /// thumbnail), so with straight lines the cover stays centred in the
  /// morphing surface all the way. MaterialApp's default arc tween sends
  /// each shuttle on its own curve.
  static RectTween flightTween(Rect? begin, Rect? end) =>
      RectTween(begin: begin, end: end);

  /// How far the page under Now Playing sits lower while covered: on
  /// dismiss it rises back into place as the surface lands.
  static const double coveredDrop = 12;

  /// Flight progress read from the shuttle's own size: 1 at the full player
  /// size, 0 at the mini player size. The hero animation cannot be used: on
  /// a diverted flight (dismiss interrupted by a reopen) Flutter keeps the
  /// shuttle, still bound to the first flight's animation, which then runs
  /// the wrong way. The rect itself is always right.
  static double _progress(double size, double mini, double full) =>
      full == mini ? 1 : ((size - mini) / (full - mini)).clamp(0.0, 1.0);

  /// Sizes of the mini and full player heroes, both laid out when a flight
  /// starts.
  static (Size mini, Size full) _ends(
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    Size sizeOf(BuildContext context) =>
        (context.findRenderObject()! as RenderBox).size;
    return direction == HeroFlightDirection.push
        ? (sizeOf(fromHeroContext), sizeOf(toHeroContext))
        : (sizeOf(toHeroContext), sizeOf(fromHeroContext));
  }

  /// Last part of the flight (in progress units) where the shuttle
  /// crossfades with the real mini player row.
  static const double _landing = 0.12;

  static double _shuttleOpacity(double t) => (t / _landing).clamp(0.0, 1.0);

  /// Route animation of the Now Playing page while it is mounted, curved
  /// like the hero flight, for the mini player row. The shell route's
  /// secondary animation cannot stand in: a fullscreen dialog does not
  /// drive it.
  static final coverAnimation = ValueNotifier<Animation<double>?>(null);

  /// The curve Flutter applies to hero flights, to build [coverAnimation].
  static CurvedAnimation curveLikeFlight(Animation<double> route) =>
      CurvedAnimation(
        parent: route,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped,
      );

  /// Opacity of the mini player row content while the Now Playing route
  /// covers it ([covering] is [coverAnimation]). The row fades in exactly as
  /// the shuttle lands and fades out as it takes off; in between only the
  /// empty glass slot shows, and the shuttle slots into it.
  static double miniRowOpacity(Animation<double> covering) =>
      1 - _shuttleOpacity(covering.value);

  static Widget surfaceShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final (mini, full) = _ends(direction, fromHeroContext, toHeroContext);
    // Rebuilt whenever the flight resizes it, i.e. every frame of the tween.
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = constraints.biggest;
        // Height: 64 px row against the ring diameter (widths are close).
        final t = _progress(size.height, mini.height, full.height);
        final radius = lerpDouble(miniSurfaceRadius, size.shortestSide / 2, t)!;
        // Crossfades with the mini row content on landing (see
        // miniRowOpacity) instead of being swapped on the last frame.
        final opacity = _shuttleOpacity(t);
        // No BackdropFilter in flight: a moving blur re-samples each frame.
        return CustomPaint(
          foregroundPainter: _ShuttleRimPainter(
            radius: radius,
            progress: t,
            opacity: opacity,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF07090E).withValues(alpha: 0.8 * opacity),
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
    );
  }

  static Widget artworkShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final (mini, full) = _ends(direction, fromHeroContext, toHeroContext);
    // Always the mini player's image: it is decoded at full size, so it is
    // ready on the first frame and sharp at any scale. The stage cover may
    // not be decoded yet at its own cache size on the first open.
    final miniContext = direction == HeroFlightDirection.push
        ? fromHeroContext
        : toHeroContext;
    final image = (miniContext.widget as Hero).child;
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = constraints.biggest;
        final t = _progress(size.width, mini.width, full.width);
        final radius = lerpDouble(miniArtworkRadius, size.shortestSide / 2, t)!;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: image,
        );
      },
    );
  }
}

/// Rim of the surface shuttle: the lens's polished edge (bright top left,
/// dim across, lit again bottom right) at the ring end, easing into the
/// mini player's even hairline as it lands.
class _ShuttleRimPainter extends CustomPainter {
  final double radius;

  /// 1 at the ring, 0 at the mini player row.
  final double progress;
  final double opacity;

  const _ShuttleRimPainter({
    required this.radius,
    required this.progress,
    required this.opacity,
  });

  /// The lens rim's gradient (GlassLens), top left to bottom right.
  static const _lens = [
    Color(0x8CFFFFFF),
    Color(0x14FFFFFF),
    Color(0x4DFFFFFF),
  ];

  /// The mini player row's even border.
  static const _row = Color(0x3DFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.4), Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lerpDouble(0.8, 1.2, progress)!
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.55, 1],
          colors: [
            for (final c in _lens)
              Color.lerp(
                _row,
                c,
                progress,
              )!.withValues(alpha: Color.lerp(_row, c, progress)!.a * opacity),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ShuttleRimPainter old) =>
      old.radius != radius ||
      old.progress != progress ||
      old.opacity != opacity;
}

/// The page under Now Playing, [NowPlayingHero.coveredDrop] lower while
/// covered. It drops only once fully covered (unseen), and rises back on
/// dismiss once it shows again, the background going, then settles after
/// the surface has landed, with a long deceleration. Still when the phone
/// asks for less motion.
class NowPlayingCoveredDrop extends StatefulWidget {
  final Widget child;

  const NowPlayingCoveredDrop({super.key, required this.child});

  /// [NowPlayingHero.coverAnimation] value below which, on dismiss, the
  /// page shows again: about when the Now Playing background starts going.
  static const double riseAt = 0.25;

  static const Duration riseDuration = Duration(milliseconds: 300);

  @override
  State<NowPlayingCoveredDrop> createState() => _NowPlayingCoveredDropState();
}

class _NowPlayingCoveredDropState extends State<NowPlayingCoveredDrop>
    with SingleTickerProviderStateMixin {
  /// 1 lowered, 0 in place.
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: NowPlayingCoveredDrop.riseDuration,
  );

  /// It only ever runs back (the drop is a jump, unseen): decelerating
  /// into place.
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _drop,
    curve: Curves.linear,
    reverseCurve: const FlippedCurve(Curves.easeOutCubic),
  );
  late final Animation<double> _offset = _curve.drive(
    Tween(begin: 0, end: NowPlayingHero.coveredDrop),
  );

  Animation<double>? _covering;

  @override
  void initState() {
    super.initState();
    NowPlayingHero.coverAnimation.addListener(_onCoverChanged);
    _onCoverChanged();
  }

  @override
  void dispose() {
    NowPlayingHero.coverAnimation.removeListener(_onCoverChanged);
    _covering?.removeListener(_follow);
    _curve.dispose();
    _drop.dispose();
    super.dispose();
  }

  void _onCoverChanged() {
    _covering?.removeListener(_follow);
    _covering = NowPlayingHero.coverAnimation.value?..addListener(_follow);
    _follow();
  }

  void _follow() {
    final covering = _covering;
    if (covering != null && covering.isCompleted) {
      // Fully covered: nobody sees the page go down.
      _drop.value = 1;
    } else if ((covering == null ||
            covering.value < NowPlayingCoveredDrop.riseAt) &&
        _drop.value > 0 &&
        _drop.status != AnimationStatus.reverse) {
      // Showing again (or Now Playing gone without a flight): rise.
      _drop.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    // One stable structure, so the page below keeps its state.
    return AnimatedBuilder(
      animation: _offset,
      child: widget.child,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, still ? 0 : _offset.value),
        child: child,
      ),
    );
  }
}
