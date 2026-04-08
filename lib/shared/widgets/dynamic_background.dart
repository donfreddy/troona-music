import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

enum DynamicBackgroundTone { ambient, immersive }

/// Extrait la couleur dominante de l'artwork en cours
/// et anime un dégradé plus vivant dérivé de la pochette.
class DynamicBackground extends StatefulWidget {
  final String? artworkPath;
  final Widget child;
  final DynamicBackgroundTone tone;

  const DynamicBackground({
    super.key,
    required this.artworkPath,
    required this.child,
    this.tone = DynamicBackgroundTone.ambient,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with TickerProviderStateMixin {
  static const _defaultColorA = Color(0xFF7B4D91);
  static const _defaultColorB = Color(0xFF4A244F);
  static const _maxPaletteCacheEntries = 48;
  static final Map<String, _CachedPalette> _paletteCache = {};

  late AnimationController _ctrl;
  late AnimationController _paletteCtrl;
  Color _fromColorA = const Color(0xFF995b8e);
  Color _fromColorB = const Color(0xFF653e78);
  Color _toColorA = const Color(0xFF995b8e);
  Color _toColorB = const Color(0xFF653e78);
  int _paletteRequestId = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 10.seconds)
      ..repeat(reverse: true);
    _paletteCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..value = 1;
    if (widget.artworkPath == null) {
      _setPaletteImmediately(_defaultColorA, _defaultColorB);
    } else {
      _hydrateOrExtract(widget.artworkPath!);
    }
  }

  @override
  void didUpdateWidget(DynamicBackground old) {
    super.didUpdateWidget(old);
    if (old.artworkPath != widget.artworkPath) {
      if (widget.artworkPath == null) {
        _paletteRequestId++;
        _animatePaletteTo(_defaultColorA, _defaultColorB);
        return;
      }
      _hydrateOrExtract(widget.artworkPath!);
    }
  }

  void _hydrateOrExtract(String path) {
    final cached = _paletteCache[_cacheKey(path)];
    if (cached != null) {
      _setPaletteImmediately(cached.colorA, cached.colorB);
      return;
    }
    _extractColor(path);
  }

  Future<void> _extractColor(String path) async {
    final requestId = ++_paletteRequestId;
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

      Color tune(
        Color c, {
        required double minLightness,
        required double maxLightness,
        required double saturationBoost,
      }) {
        final hsl = HSLColor.fromColor(c);
        return hsl
            .withSaturation((hsl.saturation * saturationBoost).clamp(0.22, 0.9))
            .withLightness(hsl.lightness.clamp(minLightness, maxLightness))
            .toColor();
      }

      final immersive = widget.tone == DynamicBackgroundTone.immersive;
      final top1 = Color.lerp(
        const Color(0xFF995b8e),
        tune(
          dominant,
          minLightness: immersive ? 0.28 : 0.34,
          maxLightness: immersive ? 0.5 : 0.58,
          saturationBoost: immersive ? 0.95 : 1.05,
        ),
        0.55,
      )!;
      final top2 = Color.lerp(
        const Color(0xFF653e78),
        tune(
          secondary,
          minLightness: immersive ? 0.16 : 0.2,
          maxLightness: immersive ? 0.34 : 0.38,
          saturationBoost: immersive ? 0.9 : 1.0,
        ),
        0.45,
      )!;

      if (!mounted || requestId != _paletteRequestId) return;
      _rememberPalette(path, top1, top2);
      _animatePaletteTo(top1, top2);
    } catch (_) {
      /* fichier inaccessible ou palette vide */
    }
  }

  void _setPaletteImmediately(Color colorA, Color colorB) {
    _fromColorA = colorA;
    _fromColorB = colorB;
    _toColorA = colorA;
    _toColorB = colorB;
    _paletteCtrl.value = 1;
  }

  void _rememberPalette(String path, Color colorA, Color colorB) {
    final key = _cacheKey(path);
    _paletteCache[key] = _CachedPalette(colorA: colorA, colorB: colorB);
    if (_paletteCache.length > _maxPaletteCacheEntries) {
      _paletteCache.remove(_paletteCache.keys.first);
    }
  }

  String _cacheKey(String path) => '${widget.tone.name}|$path';

  void _animatePaletteTo(Color nextA, Color nextB) {
    final currentA = Color.lerp(_fromColorA, _toColorA, _paletteCtrl.value)!;
    final currentB = Color.lerp(_fromColorB, _toColorB, _paletteCtrl.value)!;
    setState(() {
      _fromColorA = currentA;
      _fromColorB = currentB;
      _toColorA = nextA;
      _toColorB = nextB;
    });
    _paletteCtrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _paletteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl, _paletteCtrl]),
      builder: (_, child) {
        final t = _ctrl.value;
        final drift = sin(t * pi * 2);
        final immersive = widget.tone == DynamicBackgroundTone.immersive;
        final paletteT = Curves.easeInOutCubic.transform(_paletteCtrl.value);
        final colorA = Color.lerp(_fromColorA, _toColorA, paletteT)!;
        final colorB = Color.lerp(_fromColorB, _toColorB, paletteT)!;
        final leftCenter = Alignment(-1.1 + (drift * 0.05), -1.02);
        final rightCenter = Alignment(1.08 - (drift * 0.04), -0.98);
        final bridgeCenter = Alignment(0, -1.14 + (drift * 0.03));
        final leftGlow = Color.lerp(colorA, Colors.white, 0.08)!;
        final rightGlow = Color.lerp(colorB, Colors.white, 0.12)!;
        final bridgeGlow = Color.lerp(colorA, colorB, 0.5)!;

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: leftCenter,
                  radius: immersive ? 1.18 : 1.3,
                  stops: const [0.0, 0.36, 0.74, 1.0],
                  colors: [
                    leftGlow.withValues(alpha: immersive ? .92 : .82),
                    colorA.withValues(alpha: immersive ? .72 : .62),
                    colorA.withValues(alpha: immersive ? .18 : .12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: rightCenter,
                  radius: immersive ? 1.1 : 1.22,
                  stops: const [0.0, 0.34, 0.7, 1.0],
                  colors: [
                    rightGlow.withValues(alpha: immersive ? .88 : .78),
                    colorB.withValues(alpha: immersive ? .68 : .56),
                    colorB.withValues(alpha: immersive ? .16 : .1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: bridgeCenter,
                  radius: immersive ? 0.95 : 1.0,
                  stops: const [0.0, 0.42, 1.0],
                  colors: [
                    bridgeGlow.withValues(alpha: immersive ? .22 : .16),
                    bridgeGlow.withValues(alpha: immersive ? .08 : .05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: immersive
                      ? const [0.0, 0.24, 0.52, 0.76, 1.0]
                      : const [0.0, 0.26, 0.56, 0.8, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: immersive ? 0.08 : 0.04),
                    Colors.black.withValues(alpha: immersive ? 0.26 : 0.18),
                    Colors.black.withValues(alpha: immersive ? 0.72 : 0.64),
                    Colors.black,
                  ],
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

final class _CachedPalette {
  final Color colorA;
  final Color colorB;

  const _CachedPalette({required this.colorA, required this.colorB});
}
