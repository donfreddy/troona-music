import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final GlassConfig? config;
  final VoidCallback? onTap;

  const GlassCard({required this.child, this.config, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = config ?? GlassTheme.card(context);

    return RepaintBoundary(
      // ← isole le layer blur
      child: ClipRRect(
        borderRadius: cfg.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: cfg.blurSigma,
            sigmaY: cfg.blurSigma,
            tileMode: TileMode.clamp, // évite l'artefact de bordure
          ),
          child: _GlassDecoration(
            config: cfg,
            child: Padding(padding: cfg.padding, child: child),
          ),
        ),
      ),
    );
  }
}

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
        // Bordure glassmorphism = 3 couches superposées
        border: Border(
          // Reflet supérieur lumineux (simule la lumière sur le bord)
          top: BorderSide(color: config.border, width: config.borderWidth),
          left: BorderSide(color: config.highlight, width: config.borderWidth),
          // Bords inférieurs plus sombres / transparents
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
