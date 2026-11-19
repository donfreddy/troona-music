import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Fades [child] out over [start] logical pixels at its leading edge and
/// [end] at its trailing one, while [active].
///
/// Unlike a [ShaderMask], it costs nothing at rest: the mask layer is
/// pushed only while active, and the tree stays the same either way, so
/// the child keeps its state (a marquee keeps scrolling) when it turns on
/// or off.
class EdgeFade extends SingleChildRenderObjectWidget {
  final bool active;
  final double start;
  final double end;

  const EdgeFade({
    super.key,
    required this.active,
    required this.start,
    required this.end,
    super.child,
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

  @override
  RenderEdgeFade createRenderObject(BuildContext context) => RenderEdgeFade(
    active: active,
    start: start,
    end: end,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderEdgeFade renderObject) {
    renderObject
      ..active = active
      ..start = start
      ..end = end
      ..textDirection = Directionality.of(context);
  }
}

class RenderEdgeFade extends RenderProxyBox {
  RenderEdgeFade({
    required bool active,
    required double start,
    required double end,
    required TextDirection textDirection,
  }) : _active = active,
       _start = start,
       _end = end,
       _textDirection = textDirection;

  bool get active => _active;
  bool _active;
  set active(bool value) {
    if (value == _active) return;
    _active = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  double _start;
  set start(double value) {
    if (value == _start) return;
    _start = value;
    markNeedsPaint();
  }

  double _end;
  set end(double value) {
    if (value == _end) return;
    _end = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  final _layer = LayerHandle<ShaderMaskLayer>();

  @override
  bool get alwaysNeedsCompositing => child != null && _active;

  static const _colors = [
    Color(0x00FFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0x00FFFFFF),
  ];

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || !_active) {
      _layer.layer = null;
      super.paint(context, offset);
      return;
    }
    final rtl = _textDirection == TextDirection.rtl;
    final shader = LinearGradient(
      begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
      end: rtl ? Alignment.centerLeft : Alignment.centerRight,
      colors: _colors,
      stops: EdgeFade.stopsFor(size.width, start: _start, end: _end),
    ).createShader(Offset.zero & size);
    final layer = _layer.layer ??= ShaderMaskLayer();
    layer
      ..shader = shader
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
