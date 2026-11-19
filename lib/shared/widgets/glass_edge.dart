import 'package:flutter/widgets.dart';
import 'package:troona/core/theme/components/glass_theme.dart';

/// The edge of every glass surface that floats (the tab bar, sheets, Now
/// Playing's dock, round glass buttons, flat cards that keep one): light
/// from above, a bright top edge fading down the sides to nothing at the
/// bottom. One gradient stroke, drawn over the surface's content.
class GlassEdgePainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color top;
  final Color sides;
  final double width;

  const GlassEdgePainter({
    required this.borderRadius,
    required this.top,
    required this.sides,
    required this.width,
  });

  /// The edge of [config], around [borderRadius] when its own does not
  /// fit the surface (a circle, the bar's corners).
  GlassEdgePainter.of(GlassConfig config, {BorderRadius? borderRadius})
    : this(
        borderRadius: borderRadius ?? config.borderRadius,
        top: config.border,
        sides: config.highlight,
        width: config.borderWidth,
      );

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0 || (top.a == 0 && sides.a == 0)) return;
    final rect = Offset.zero & size;
    final stroke = rect.deflate(width / 2);
    if (stroke.isEmpty) return;
    canvas.drawRRect(
      borderRadius.toRRect(stroke),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, sides, sides.withValues(alpha: 0)],
          stops: const [0, .45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(GlassEdgePainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.top != top ||
      oldDelegate.sides != sides ||
      oldDelegate.width != width;
}

/// A soft shadow around a floating surface, painted outside its rounded
/// rect only: glass that blurs what is behind it would otherwise take the
/// shadow under it in and darken.
class OuterShadowPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color color;
  final double blurSigma;
  final Offset offset;

  const OuterShadowPainter({
    required this.borderRadius,
    this.color = const Color(0x66000000),
    this.blurSigma = 12,
    this.offset = const Offset(0, 8),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final surface = borderRadius.toRRect(Offset.zero & size);
    final reach = blurSigma * 3 + offset.distance;
    canvas
      ..save()
      ..clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect((Offset.zero & size).inflate(reach)),
          Path()..addRRect(surface),
        ),
      )
      ..drawRRect(
        surface.shift(offset),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(OuterShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.color != color ||
      oldDelegate.blurSigma != blurSigma ||
      oldDelegate.offset != offset;
}
