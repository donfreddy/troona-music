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
