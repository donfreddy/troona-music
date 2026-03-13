import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

/// Extrait la couleur dominante de l'artwork en cours
/// et anime un dégradé violet→couleur dominant→noir
/// identique au design fourni.
class DynamicBackground extends StatefulWidget {
  final String? artworkPath;
  final Widget child;

  const DynamicBackground({super.key, required this.artworkPath, required this.child});

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Color _from = const Color(0xFF1A0533); // violet par défaut
  Color _to = const Color(0xFF1A0533);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 800.ms);
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
      final color =
          palette.darkVibrantColor?.color ??
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          const Color(0xFF1A0533);

      // Assombrit la couleur pour qu'elle reste lisible
      final hsl = HSLColor.fromColor(color);
      final dark = hsl.withLightness((hsl.lightness * 0.45).clamp(0.08, 0.35)).toColor();

      if (mounted) {
        setState(() {
          _from = _to;
          _to = dark;
        });
        _ctrl.forward(from: 0);
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
        final color = Color.lerp(_from, _to, _ctrl.value)!;
        return DecoratedBox(
          decoration: BoxDecoration(
            // Dégradé identique aux screenshots : couleur dominante en haut,
            // fondu vers noir en bas
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.45, 1.0],
              colors: [color, color.withValues(alpha: .6), Colors.black],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
