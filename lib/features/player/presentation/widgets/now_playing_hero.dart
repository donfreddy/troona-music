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
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF07090E).withValues(alpha: 0.8 * opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24 * opacity),
              width: 0.8,
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
