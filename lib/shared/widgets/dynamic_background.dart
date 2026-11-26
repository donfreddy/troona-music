import 'package:flutter/material.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';
import 'package:troona/core/theme/semantic/palette_ink.dart';

enum DynamicBackgroundTone { ambient, immersive }

/// Paints a two-color glow background, cross-fading when [colorA]/[colorB]
/// change. Colors are computed externally (e.g. by [TrackPaletteCubit]), so
/// this widget does no palette extraction. It darkens them, if needed, so
/// text stays readable over the glow ([fitForText]).
///
/// The glow is deliberately static between track changes: a continuously
/// animated background forces every [BackdropFilter] above it to re-blur
/// on each frame.
class DynamicBackground extends StatefulWidget {
  final Color? colorA;
  final Color? colorB;
  final Widget child;
  final DynamicBackgroundTone tone;

  /// False paints black: the glow fades out over [transitionOf], and the
  /// tree below stays the same, so [child] keeps its state.
  final bool glow;

  const DynamicBackground({
    super.key,
    required this.colorA,
    required this.colorB,
    required this.child,
    this.tone = DynamicBackgroundTone.ambient,
    this.glow = true,
  });

  /// How long the glow takes to follow a new song on [glass]: slowly
  /// behind the tabs, where it sets the mood; quickly on Now Playing and
  /// the detail pages, where it follows a swipe of the covers. A
  /// transition costs a re-blur of every [BackdropFilter] above it on each
  /// frame, so it stays short where two of them sit on screen for long,
  /// and everywhere below the high tier, on devices that can least afford
  /// the frames.
  static Duration transitionOf(
    DynamicBackgroundTone tone, [
    GlassQuality glass = GlassQuality.high,
  ]) => tone == DynamicBackgroundTone.ambient && glass == GlassQuality.high
      ? const Duration(seconds: 2)
      : const Duration(milliseconds: 380);

  /// Brightest a glow may paint: secondary labels (60 % white) keep 4.5:1
  /// over it. Measured as relative luminance: by HSL lightness, a yellow
  /// cover comes out five times brighter than a blue one.
  static const maxGlowLuminance = 0.032;

  /// [color] with its hue kept, darkened until its glow paints at most
  /// [maxGlowLuminance]. Dark colours come back unchanged.
  static Color fitForText(Color color) {
    var hsl = HSLColor.fromColor(color);
    while (peakOf(hsl.toColor()).computeLuminance() > maxGlowLuminance &&
        hsl.lightness > 0) {
      hsl = hsl.withLightness((hsl.lightness - .01).clamp(0.0, 1.0));
    }
    return hsl.toColor();
  }

  /// The brightest pixel a glow of [color] paints on black: an upper bound
  /// of both glows in both tones (at most 12 % towards white, 92 % alpha).
  /// Where the glows overlap, each is well below its peak.
  @visibleForTesting
  static Color peakOf(Color color) => PaletteInk.glowPeakOf(color);

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

/// The two glow colours as [DynamicBackground] paints them on each frame:
/// fitted for text, and cross-faded to a new song's from wherever they
/// are. What must follow the glow in step (the text over it) owns one,
/// fed the same colours and the same [DynamicBackgroundTone].
final class GlowCrossFade {
  static const _defaultColorA = ColorPrimitives.ambientTop;
  static const _defaultColorB = ColorPrimitives.ambientEdge;

  final AnimationController _ctrl;
  Color _fromA;
  Color _fromB;
  Color _toA;
  Color _toB;

  GlowCrossFade._(this._ctrl, Color a, Color b)
    : _fromA = a,
      _fromB = b,
      _toA = a,
      _toB = b;

  /// Shows [colorA] and [colorB] at once (null: the app's ambient glow).
  factory GlowCrossFade({
    required TickerProvider vsync,
    required Color? colorA,
    required Color? colorB,
    required DynamicBackgroundTone tone,
  }) => GlowCrossFade._(
    AnimationController(
      vsync: vsync,
      duration: DynamicBackground.transitionOf(tone),
    )..value = 1,
    DynamicBackground.fitForText(colorA ?? _defaultColorA),
    DynamicBackground.fitForText(colorB ?? _defaultColorB),
  );

  /// Ticks while the glow moves.
  Animation<double> get animation => _ctrl;

  /// How long a move takes, as [follow] last set it.
  Duration get duration => _ctrl.duration!;

  /// Follows the glass setting, read where the glow is shown.
  void follow(BuildContext context, DynamicBackgroundTone tone) =>
      _ctrl.duration = DynamicBackground.transitionOf(
        tone,
        GlassTheme.resolveQuality(context),
      );

  /// The colours painted now.
  (Color, Color) get colors {
    final t = Curves.easeInOutCubic.transform(_ctrl.value);
    return (Color.lerp(_fromA, _toA, t)!, Color.lerp(_fromB, _toB, t)!);
  }

  /// Moves to [colorA] and [colorB] from the colours painted now; nothing
  /// when they are already the target.
  void moveTo(Color? colorA, Color? colorB) {
    final nextA = DynamicBackground.fitForText(colorA ?? _defaultColorA);
    final nextB = DynamicBackground.fitForText(colorB ?? _defaultColorB);
    if (nextA == _toA && nextB == _toB) return;
    final (fromA, fromB) = colors;
    _fromA = fromA;
    _fromB = fromB;
    _toA = nextA;
    _toB = nextB;
    _ctrl
      ..reset()
      ..forward();
  }

  void dispose() => _ctrl.dispose();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with SingleTickerProviderStateMixin {
  late final GlowCrossFade _glow = GlowCrossFade(
    vsync: this,
    colorA: widget.colorA,
    colorB: widget.colorB,
    tone: widget.tone,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _glow.follow(context, widget.tone);
  }

  @override
  void didUpdateWidget(DynamicBackground old) {
    super.didUpdateWidget(old);
    _glow
      ..follow(context, widget.tone)
      ..moveTo(widget.colorA, widget.colorB);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow.animation,
      builder: (_, child) {
        final immersive = widget.tone == DynamicBackgroundTone.immersive;
        final (colorA, colorB) = _glow.colors;
        const leftCenter = Alignment(-1.1, -1.02);
        const rightCenter = Alignment(1.08, -0.98);
        const bridgeCenter = Alignment(0, -1.14);
        final leftGlow = Color.lerp(colorA, Colors.white, 0.08)!;
        final rightGlow = Color.lerp(colorB, Colors.white, 0.12)!;
        final bridgeGlow = Color.lerp(colorA, colorB, 0.5)!;

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            AnimatedOpacity(
              opacity: widget.glow ? 1 : 0,
              duration: _glow.duration,
              child: Stack(
                fit: StackFit.expand,
                children: [
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
                          Colors.black.withValues(
                            alpha: immersive ? 0.08 : 0.04,
                          ),
                          Colors.black.withValues(
                            alpha: immersive ? 0.26 : 0.18,
                          ),
                          Colors.black.withValues(
                            alpha: immersive ? 0.72 : 0.64,
                          ),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ],
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
