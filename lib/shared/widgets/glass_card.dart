import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/components/glass_filter.dart';

/// A glass-styled card that adapts fill and border to the current
/// [GlassQuality] preset and device brightness.
///
/// Flat by default: cards sit in scrolling content, and blur is kept for
/// chrome (bars, headers, sheets), as on iOS. Pass a [config] with a blur to
/// opt in (e.g. [GlassTheme.miniPlayer] for the mini-player surface).
///
/// **Rendering contract**:
/// - [BackdropFilter] is only created when [GlassConfig.blurSigma] > 0.
/// - Always wrapped in [RepaintBoundary] to isolate the compositing layer.
/// - Never place inside an [AnimatedBuilder] driven by the audio position
///   stream: that would trigger a full blur redraw at 60 fps.
class GlassCard extends StatelessWidget {
  final Widget child;

  /// Optional override for the resolved [GlassConfig].
  /// Defaults to [GlassTheme.card] without blur when null.
  final GlassConfig? config;

  /// Optional tap callback.  When non-null the card wraps itself in a
  /// [GestureDetector] so the entire surface is tappable.
  final VoidCallback? onTap;

  const GlassCard({required this.child, this.config, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = config ?? GlassTheme.card(context).copyWith(blurSigma: 0);

    final content = _GlassDecoration(
      config: cfg,
      child: Padding(padding: cfg.padding, child: child),
    );

    Widget card;

    if (cfg.blurSigma == 0) {
      // Fast path: skip BackdropFilter entirely: no compositing layer cost.
      // _GlassDecoration already draws the fill and border; just clip.
      card = ClipRRect(borderRadius: cfg.borderRadius, child: content);
    } else {
      card = RepaintBoundary(
        child: ClipRRect(
          borderRadius: cfg.borderRadius,
          child: BackdropFilter(
            filter: GlassFilter.of(cfg.blurSigma),
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

/// Draws the glass fill and its edge.
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
      foregroundPainter: _GlassEdgePainter(
        borderRadius: config.borderRadius,
        top: config.border,
        sides: config.highlight,
        width: config.borderWidth,
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

/// Light from above: a bright top edge fading down the sides to nothing at
/// the bottom. One gradient stroke.
class _GlassEdgePainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color top;
  final Color sides;
  final double width;

  const _GlassEdgePainter({
    required this.borderRadius,
    required this.top,
    required this.sides,
    required this.width,
  });

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
  bool shouldRepaint(_GlassEdgePainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.top != top ||
      oldDelegate.sides != sides ||
      oldDelegate.width != width;
}
