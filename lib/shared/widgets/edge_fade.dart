import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Fades [child] out over [start] logical pixels at its leading edge and
/// [end] at its trailing one, while [active]. A [ShaderMaskWhile]: nothing
/// at rest, and the child keeps its state when it turns on or off.
class EdgeFade extends StatelessWidget {
  final bool active;
  final double start;
  final double end;
  final Widget? child;

  const EdgeFade({
    super.key,
    required this.active,
    required this.start,
    required this.end,
    this.child,
  });

  /// The mask's stops over [width], leading edge first: transparent at 0,
  /// opaque from the second stop to the third, transparent at 1. Too narrow
  /// for both fades, they meet in the middle.
  static List<double> stopsFor(
    double width, {
    required double start,
    required double end,
  }) {
    final w = math.max(width, 1.0);
    final lead = math.min(start / w, .5);
    final trail = math.max(1 - end / w, lead);
    return [0, lead, trail, 1];
  }

  static const _colors = [
    Color(0x00FFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0x00FFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ShaderMaskWhile(
      active: active,
      shaderCallback: (bounds) => LinearGradient(
        begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
        end: rtl ? Alignment.centerLeft : Alignment.centerRight,
        colors: _colors,
        stops: stopsFor(bounds.width, start: start, end: end),
      ).createShader(bounds),
      child: child,
    );
  }
}

/// A [ShaderMask] (with [BlendMode.dstIn]) applied only while [active].
///
/// A [ShaderMask] costs a layer even when its shader changes nothing, and
/// adding or removing one changes the tree, so the child would lose its
/// state. This one pushes its layer only while active, in the same tree
/// either way.
class ShaderMaskWhile extends SingleChildRenderObjectWidget {
  final bool active;

  /// Called with the child's bounds, at the origin, on each paint while
  /// active.
  final ShaderCallback shaderCallback;

  const ShaderMaskWhile({
    super.key,
    required this.active,
    required this.shaderCallback,
    super.child,
  });

  @override
  RenderShaderMaskWhile createRenderObject(BuildContext context) =>
      RenderShaderMaskWhile(active: active, shaderCallback: shaderCallback);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderShaderMaskWhile renderObject,
  ) {
    renderObject
      ..active = active
      ..shaderCallback = shaderCallback;
  }
}

class RenderShaderMaskWhile extends RenderProxyBox {
  RenderShaderMaskWhile({
    required bool active,
    required ShaderCallback shaderCallback,
  }) : _active = active,
       _shaderCallback = shaderCallback;

  bool get active => _active;
  bool _active;
  set active(bool value) {
    if (value == _active) return;
    _active = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  ShaderCallback get shaderCallback => _shaderCallback;
  ShaderCallback _shaderCallback;
  set shaderCallback(ShaderCallback value) {
    if (value == _shaderCallback) return;
    _shaderCallback = value;
    // A new closure each build may draw a new mask: repaint while it shows.
    if (_active) markNeedsPaint();
  }

  final _layer = LayerHandle<ShaderMaskLayer>();

  @override
  bool get alwaysNeedsCompositing => child != null && _active;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || !_active) {
      _layer.layer = null;
      super.paint(context, offset);
      return;
    }
    final layer = _layer.layer ??= ShaderMaskLayer();
    layer
      ..shader = _shaderCallback(Offset.zero & size)
      ..maskRect = offset & size
      ..blendMode = BlendMode.dstIn;
    context.pushLayer(layer, super.paint, offset);
  }

  @override
  void dispose() {
    _layer.layer = null;
    super.dispose();
  }
}
