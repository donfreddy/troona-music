import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';

/// Fixed frosted-glass ring of the Now Playing stage.
///
/// The ring never moves: artworks slide underneath it, so a neighbour cover
/// turns frosted while it crosses the ring and sharp again inside the hole.
/// That costs a single [BackdropFilter], clipped to the annulus.
///
/// Always place it inside an [IgnorePointer]: it is purely decorative.
class GlassLens extends StatelessWidget {
  /// Outer diameter of the ring.
  final double diameter;

  /// Diameter of the clear hole in the middle (the active artwork).
  final double holeDiameter;

  const GlassLens({
    super.key,
    required this.diameter,
    required this.holeDiameter,
  });

  /// Frosted enough to blur neighbour covers, light enough to stay cheap.
  static const double _maxBlurSigma = 12;

  /// Radius of the thin inner line, as a fraction of the outer radius. The
  /// progress arc is drawn on it.
  static const double hairlineFraction = 0.795;

  @override
  Widget build(BuildContext context) {
    final holeFraction = holeDiameter / diameter;
    final sigma = math.min(GlassTheme.card(context).blurSigma, _maxBlurSigma);
    final clipper = _AnnulusClipper(holeFraction);

    const fill = ColoredBox(color: Color(0x14FFFFFF), child: SizedBox.expand());

    return RepaintBoundary(
      child: SizedBox.square(
        dimension: diameter,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipPath(
              clipper: clipper,
              child: sigma == 0
                  ? fill
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                      child: fill,
                    ),
            ),
            CustomPaint(painter: _LensRimPainter(holeFraction)),
          ],
        ),
      ),
    );
  }
}

/// Ring shape: the outer disc minus the hole, via the even-odd fill rule.
class _AnnulusClipper extends CustomClipper<Path> {
  final double holeFraction;

  const _AnnulusClipper(this.holeFraction);

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..addOval(Rect.fromCircle(center: center, radius: radius * holeFraction));
  }

  @override
  bool shouldReclip(_AnnulusClipper oldClipper) =>
      oldClipper.holeFraction != holeFraction;
}

/// Glass thickness and polished edges: a radial sheen across the ring, a
/// light-catching outer rim, an inner hairline and a soft hole edge.
class _LensRimPainter extends CustomPainter {
  final double holeFraction;

  const _LensRimPainter(this.holeFraction);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final outer = Rect.fromCircle(center: center, radius: radius);
    final holeRadius = radius * holeFraction;

    // Sheen: clear at the hole, slightly lit towards the rim.
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(outer)
      ..addOval(Rect.fromCircle(center: center, radius: holeRadius));
    canvas.drawPath(
      ring,
      Paint()
        ..shader = RadialGradient(
          stops: [holeFraction, 1],
          colors: const [Color(0x00FFFFFF), Color(0x14FFFFFF)],
        ).createShader(outer),
    );

    // Outer rim: brighter where light hits (top left), dimmer elsewhere.
    canvas.drawCircle(
      center,
      radius - 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8CFFFFFF), Color(0x14FFFFFF), Color(0x4DFFFFFF)],
          stops: [0, 0.55, 1],
        ).createShader(outer),
    );

    // Inner hairline, as in the reference.
    canvas.drawCircle(
      center,
      radius * GlassLens.hairlineFraction,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x1FFFFFFF),
    );

    // Hole edge: separates the sharp artwork from the frosted glass.
    canvas.drawCircle(
      center,
      holeRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x24FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_LensRimPainter oldDelegate) =>
      oldDelegate.holeFraction != holeFraction;
}
