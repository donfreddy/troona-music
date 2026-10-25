import 'package:flutter/material.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';

enum DynamicBackgroundTone { ambient, immersive }

/// Paints a two-color glow background, cross-fading when [colorA]/[colorB]
/// change. Colors are computed externally (e.g. by [TrackPaletteCubit]) so
/// this widget does no palette extraction and never touches the UI isolate.
///
/// The glow is deliberately static between track changes: a continuously
/// animated background forces every [BackdropFilter] above it to re-blur
/// on each frame.
class DynamicBackground extends StatefulWidget {
  final Color? colorA;
  final Color? colorB;
  final Widget child;
  final DynamicBackgroundTone tone;

  const DynamicBackground({
    super.key,
    required this.colorA,
    required this.colorB,
    required this.child,
    this.tone = DynamicBackgroundTone.ambient,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with SingleTickerProviderStateMixin {
  static const _defaultColorA = ColorPrimitives.ambientTop;
  static const _defaultColorB = ColorPrimitives.ambientEdge;

  late AnimationController _ctrl;
  Color _fromA = _defaultColorA;
  Color _fromB = _defaultColorB;
  Color _toA = _defaultColorA;
  Color _toB = _defaultColorB;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..value = 1;
    final a = widget.colorA ?? _defaultColorA;
    final b = widget.colorB ?? _defaultColorB;
    _fromA = a;
    _fromB = b;
    _toA = a;
    _toB = b;
  }

  @override
  void didUpdateWidget(DynamicBackground old) {
    super.didUpdateWidget(old);
    final newA = widget.colorA ?? _defaultColorA;
    final newB = widget.colorB ?? _defaultColorB;
    final oldA = old.colorA ?? _defaultColorA;
    final oldB = old.colorB ?? _defaultColorB;
    if (newA != oldA || newB != oldB) {
      _animateTo(newA, newB);
    }
  }

  void _animateTo(Color nextA, Color nextB) {
    final t = Curves.easeInOutCubic.transform(_ctrl.value);
    final currentA = Color.lerp(_fromA, _toA, t)!;
    final currentB = Color.lerp(_fromB, _toB, t)!;
    setState(() {
      _fromA = currentA;
      _fromB = currentB;
      _toA = nextA;
      _toB = nextB;
    });
    _ctrl
      ..reset()
      ..forward();
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
        final immersive = widget.tone == DynamicBackgroundTone.immersive;
        final t = Curves.easeInOutCubic.transform(_ctrl.value);
        final colorA = Color.lerp(_fromA, _toA, t)!;
        final colorB = Color.lerp(_fromB, _toB, t)!;
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
