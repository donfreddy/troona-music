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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: config.fill,
        borderRadius: config.borderRadius,
        // Three-layer border simulates the iOS luminosity highlight:
        //   top   — bright edge (primary light-source reflection)
        //   left  — subtle diagonal sheen
        //   bottom/right — near-transparent (shadowed edges)
        border: Border(
          top: BorderSide(color: config.border, width: config.borderWidth),
          left: BorderSide(color: config.highlight, width: config.borderWidth),
          bottom: BorderSide(
            color: config.highlight.withValues(alpha: .05),
            width: 0.5,
          ),
          right: BorderSide(
            color: config.highlight.withValues(alpha: .05),
            width: 0.5,
          ),
        ),
      ),
      child: child,
    );
  }
}
