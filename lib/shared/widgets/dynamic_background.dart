import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

/// Extrait la couleur dominante de l'artwork en cours
/// et anime un dégradé violet→couleur dominant→noir
/// identique au design fourni.
class DynamicBackground extends StatefulWidget {
  final String? artworkPath;
  final Widget child;

  const DynamicBackground({
    super.key,
    required this.artworkPath,
    required this.child,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Color _colorA = const Color(0xFF1A0533); // violet par défaut
  Color _colorB = const Color(0xFF1A0533);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 10.seconds)
      ..repeat(reverse: true);
    _extractColor(widget.artworkPath);
  }

  @override
  void didUpdateWidget(DynamicBackground old) {
    super.didUpdateWidget(old);
    if (old.artworkPath != widget.artworkPath) {
      _extractColor(widget.artworkPath);
    }
  }

  Future<void> _extractColor(String? path) async {
    if (path == null) return;
    try {
      final palette = await PaletteGeneratorMaster.fromImageProvider(
        FileImage(File(path)),
        size: const Size(100, 100), // thumbnail pour la perf
      );
      final dominant =
          palette.darkVibrantColor?.color ??
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          const Color(0xFF1A0533);

      // Prend une deuxième teinte (vibrant si dispo) pour l'animation
      final secondary =
          palette.vibrantColor?.color ??
          palette.lightVibrantColor?.color ??
          palette.mutedColor?.color ??
          dominant;

      // Assombrit pour garder la lisibilité — la base sombre reste en bas.
      Color darken(Color c, double factor) {
        final hsl = HSLColor.fromColor(c);
        return hsl
            .withLightness((hsl.lightness * factor).clamp(0.08, 0.4))
            .toColor();
      }

      final top1 = darken(dominant, 0.55);
      final top2 = darken(secondary, 0.65);

      if (mounted) {
        setState(() {
          _colorA = top1;
          _colorB = top2;
        });
      }
    } catch (_) {
      /* fichier inaccessible ou palette vide */
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final wobble = sin(t * pi); // 0→1→0
        final mixedTop = Color.lerp(_colorA, _colorB, wobble)!;
        final angle = lerpDouble(-12.0, 12.0, t)! * pi / 180;
        final begin = _rotateAlignment(Alignment.topCenter, angle);
        final end = Alignment.bottomCenter;
        return DecoratedBox(
          decoration: BoxDecoration(
            // Dégradé animé : deux teintes en haut, fond noir fixe en bas
            gradient: LinearGradient(
              begin: begin,
              end: end,
              stops: const [0.0, 0.25, 0.6, 1.0],
              colors: [
                mixedTop,
                _colorA.withValues(alpha: .6),
                _colorB.withValues(alpha: .35),
                Colors.black, // le bas reste sombre
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }

  Alignment _rotateAlignment(Alignment base, double angleRad) {
    final cosA = cos(angleRad);
    final sinA = sin(angleRad);
    final x = base.x * cosA - base.y * sinA;
    final y = base.x * sinA + base.y * cosA;
    return Alignment(x, y);
  }
}
