import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

enum DynamicBackgroundTone { ambient, immersive }

/// Extracts the dominant color from the current artwork
/// and animates a vibrant gradient derived from the cover.
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
        size: const Size(64, 64), // Smaller = faster and more "averaged"
      );

      // Strategy: Look for the most representative color
      // but saturated enough not to be grey.
      final primaryColor =
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          const Color(0xFF1A0533);

      final secondaryColor =
          palette.darkVibrantColor?.color ??
          palette.mutedColor?.color ??
          primaryColor;

      // Function to harmonize the color without denaturing it
      Color adapt(Color c, {required bool isTop}) {
        final hsl = HSLColor.fromColor(c);
        // Keep the Hue intact!
        // Just adjust saturation to make it "pop"
        // and lightness to keep the background dark (readability)
        return hsl
            .withSaturation((hsl.saturation * 1.1).clamp(0.4, 0.9))
            .withLightness(isTop ? 0.25 : 0.15)
            .toColor();
      }

      final top1 = adapt(primaryColor, isTop: true);
      final top2 = adapt(secondaryColor, isTop: false);

      if (!mounted || requestId != _paletteRequestId) return;
      _rememberPalette(path, top1, top2);
      _animatePaletteTo(top1, top2);
    } catch (_) {
      /* inaccessible file or empty palette */
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
    // Take a snapshot of the current animated colors to use as a starting point for the next transition.
    // This prevents "jumps" if a new artwork is loaded before the previous animation finished.
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
