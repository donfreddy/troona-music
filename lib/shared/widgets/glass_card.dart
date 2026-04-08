import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';

/// A glass-styled content card that adapts blur, fill, and border to the
/// current [GlassQuality] preset and device brightness.
///
/// Pass a custom [config] to override the default [GlassTheme.card] preset
/// (e.g. use [GlassTheme.miniPlayer] for the mini-player surface).
///
/// **Rendering contract**:
/// - [BackdropFilter] is only created when [GlassConfig.blurSigma] > 0.
/// - Always wrapped in [RepaintBoundary] to isolate the compositing layer.
/// - Never place inside an [AnimatedBuilder] driven by the audio position
///   stream — that would trigger a full blur redraw at 60 fps.
class GlassCard extends StatelessWidget {
  final Widget child;

  /// Optional override for the resolved [GlassConfig].
  /// Defaults to [GlassTheme.card] when null.
  final GlassConfig? config;

  /// Optional tap callback.  When non-null the card wraps itself in a
  /// [GestureDetector] so the entire surface is tappable.
  final VoidCallback? onTap;

  const GlassCard({required this.child, this.config, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = config ?? GlassTheme.card(context);

    final content = _GlassDecoration(
      config: cfg,
      child: Padding(padding: cfg.padding, child: child),
    );

    Widget card;

    if (cfg.blurSigma == 0) {
      // Fast path: skip BackdropFilter entirely — no compositing layer cost.
      // _GlassDecoration already draws the fill and border; just clip.
      card = ClipRRect(borderRadius: cfg.borderRadius, child: content);
    } else {
      card = RepaintBoundary(
        child: ClipRRect(
          borderRadius: cfg.borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: cfg.blurSigma,
              sigmaY: cfg.blurSigma,
              tileMode: TileMode.clamp,
            ),
            child: content,
          ),
        ),
      );
    }

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

/// Draws the glass fill, three-layer border, and optional highlight sheen.
///
/// Kept as a separate widget so it can be composed inside or outside a
/// [BackdropFilter] without duplicating decoration logic.
class _GlassDecoration extends StatelessWidget {
  final GlassConfig config;
  final Widget child;

  const _GlassDecoration({required this.config, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _GlassBorderPainter(
        borderRadius: config.borderRadius,
        topColor: config.border,
        leftColor: config.highlight,
        bottomColor: config.highlight.withValues(alpha: .05),
        rightColor: config.highlight.withValues(alpha: .05),
        topWidth: config.borderWidth,
        leftWidth: config.borderWidth,
        bottomWidth: 0.5,
        rightWidth: 0.5,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: config.fill,
          borderRadius: config.borderRadius,
        ),
        child: child,
      ),
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color topColor;
  final Color leftColor;
  final Color bottomColor;
  final Color rightColor;
  final double topWidth;
  final double leftWidth;
  final double bottomWidth;
  final double rightWidth;

  const _GlassBorderPainter({
    required this.borderRadius,
    required this.topColor,
    required this.leftColor,
    required this.bottomColor,
    required this.rightColor,
    required this.topWidth,
    required this.leftWidth,
    required this.bottomWidth,
    required this.rightWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    _paintEdge(
      canvas,
      rect,
      Rect.fromLTWH(0, 0, size.width, size.height / 2),
      topColor,
      topWidth,
    );
    _paintEdge(
      canvas,
      rect,
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      leftColor,
      leftWidth,
    );
    _paintEdge(
      canvas,
      rect,
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      bottomColor,
      bottomWidth,
    );
    _paintEdge(
      canvas,
      rect,
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      rightColor,
      rightWidth,
    );
  }

  void _paintEdge(
    Canvas canvas,
    Rect rect,
    Rect clipRect,
    Color color,
    double width,
  ) {
    if (width <= 0 || color.a == 0) return;

    final strokeRect = rect.deflate(width / 2);
    if (strokeRect.width <= 0 || strokeRect.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.save();
    canvas.clipRect(clipRect);
    canvas.drawRRect(borderRadius.toRRect(strokeRect), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.topColor != topColor ||
      oldDelegate.leftColor != leftColor ||
      oldDelegate.bottomColor != bottomColor ||
      oldDelegate.rightColor != rightColor ||
      oldDelegate.topWidth != topWidth ||
      oldDelegate.leftWidth != leftWidth ||
      oldDelegate.bottomWidth != bottomWidth ||
      oldDelegate.rightWidth != rightWidth;
}
