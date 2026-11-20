import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The orb at the centre of the tab bar: a small sphere in the colours of
/// the song playing, the app's accent when nothing is loaded.
///
/// It moves at moments only: its colours swirl to a new song's, and it
/// pulses once when playback starts or stops. At rest it runs no ticker.
/// The bar is glass: a perpetual animation inside it would ask for a frame
/// at every refresh, and every blur on screen is computed again with each
/// frame.
class PlayingOrb extends StatefulWidget {
  /// The lit side of the sphere, and its shaded side.
  final Color top;
  final Color edge;

  /// Whether music plays now: brighter, and a pulse on every change.
  final bool live;

  final double size;

  const PlayingOrb({
    super.key,
    required this.top,
    required this.edge,
    required this.live,
    this.size = 52,
  });

  /// How long the colours take to swirl to a new song's.
  static const swirl = Duration(milliseconds: 700);

  /// How long the pulse of a play or a pause lasts.
  static const pulse = Duration(milliseconds: 320);

  /// The orb's colours for a song whose background glows in [a] and [b]
  /// (dark, as the page background wants them): the same hues, vivid and
  /// light enough to read as a lit object on the bar. Two covers colours
  /// of one hue would make a flat ball: the shaded side then moves a
  /// little round the colour wheel. A grey cover gives a grey orb, never
  /// a hue it does not have.
  static (Color top, Color edge) colorsFor(Color a, Color b) {
    final top = HSLColor.fromColor(a);
    var edge = HSLColor.fromColor(b);
    final apart = ((top.hue - edge.hue + 540) % 360 - 180).abs();
    if (apart < _hueApart && top.saturation >= _grey) {
      edge = edge.withHue((top.hue - _hueShift) % 360);
    }
    return (_lit(top, 0.6), _lit(edge, 0.34));
  }

  /// The orb's colours with nothing loaded, from the app's [accent].
  static (Color top, Color edge) resting(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    return (accent, _lit(hsl.withHue((hsl.hue - _hueShift) % 360), 0.34));
  }

  /// Below this saturation a colour is a grey, and stays one.
  static const double _grey = 0.15;
  static const double _hueApart = 25;
  static const double _hueShift = 42;

  static Color _lit(HSLColor color, double lightness) => color
      .withSaturation(
        color.saturation < _grey ? 0.08 : color.saturation.clamp(0.6, 0.92),
      )
      .withLightness(lightness)
      .toColor();

  @override
  State<PlayingOrb> createState() => _PlayingOrbState();
}

class _PlayingOrbState extends State<PlayingOrb> with TickerProviderStateMixin {
  /// 0 to 1 over each change of colours.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: PlayingOrb.swirl,
    value: 1,
  );

  /// 0 idle, 1 playing.
  late final AnimationController _live = AnimationController(
    vsync: this,
    duration: PlayingOrb.pulse,
    value: widget.live ? 1 : 0,
  );

  late Color _fromTop = widget.top;
  late Color _fromEdge = widget.edge;
  double _angleFrom = 0;
  double _angleTo = 0;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(PlayingOrb old) {
    super.didUpdateWidget(old);
    if (old.top != widget.top || old.edge != widget.edge) {
      // From wherever a change still under way had got to.
      final t = Curves.easeOutCubic.transform(_turn.value);
      _fromTop = Color.lerp(_fromTop, old.top, t)!;
      _fromEdge = Color.lerp(_fromEdge, old.edge, t)!;
      _angleFrom = lerpDouble(_angleFrom, _angleTo, t)!;
      if (_still) {
        _angleTo = _angleFrom;
        _turn.value = 1;
      } else {
        _angleTo = _angleFrom + math.pi * 0.9;
        _turn.forward(from: 0);
      }
    }
    if (old.live != widget.live) {
      final target = widget.live ? 1.0 : 0.0;
      if (_still) {
        _live.value = target;
      } else {
        _live.animateTo(target, curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _OrbPainter(
          turn: _turn,
          live: _live,
          fromTop: _fromTop,
          fromEdge: _fromEdge,
          toTop: widget.top,
          toEdge: widget.edge,
          angleFrom: _angleFrom,
          angleTo: _angleTo,
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final Animation<double> turn;
  final Animation<double> live;
  final Color fromTop;
  final Color fromEdge;
  final Color toTop;
  final Color toEdge;
  final double angleFrom;
  final double angleTo;

  _OrbPainter({
    required this.turn,
    required this.live,
    required this.fromTop,
    required this.fromEdge,
    required this.toTop,
    required this.toEdge,
    required this.angleFrom,
    required this.angleTo,
  }) : super(repaint: Listenable.merge([turn, live]));

  /// Room kept around the sphere for its pulse.
  static const _rest = 0.9;
  static const _swell = 0.08;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(turn.value);
    final top = Color.lerp(fromTop, toTop, t)!;
    final edge = Color.lerp(fromEdge, toEdge, t)!;
    final angle = lerpDouble(angleFrom, angleTo, t)!;
    final playing = live.value;
    // Brighter while music plays; a swell on the way between the two.
    final energy = lerpDouble(0.55, 1, playing)!;
    final swell = math.sin(math.pi * playing) * _swell;

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 * (_rest + swell);
    final sphere = Rect.fromCircle(center: center, radius: radius);
    // The ribbons inside: the lit colour, turned a little either way
    // round the wheel, so the orb shimmers instead of being one tone.
    final lit = HSLColor.fromColor(top);
    Color ribbon(double hueBy, double alpha) => lit
        .withHue((lit.hue + hueBy) % 360)
        .withLightness(0.78)
        .toColor()
        .withValues(alpha: alpha * energy);
    Paint soft(Color color, double blur) => Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * blur);
    Paint stroke(Color color, double width, double blur) => soft(color, blur)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * width;
    Rect ring(double dx, double dy, double scale) => Rect.fromCircle(
      center: center + Offset(dx, dy) * radius,
      radius: radius * scale,
    );

    canvas
      ..save()
      ..clipPath(Path()..addOval(sphere))
      // The body: deep, lit from the top left.
      ..drawRect(
        sphere,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.2,
            colors: [
              Color.lerp(top, Colors.white, 0.18 * energy)!,
              Color.lerp(top, edge, 0.45)!,
              edge,
              Color.lerp(edge, Colors.black, 0.72)!,
            ],
            stops: const [0, 0.3, 0.62, 1],
          ).createShader(sphere),
      )
      // What moves inside it: three ribbons of light, turned by the swirl.
      // They cross the sphere on a slant: level, the two below the middle
      // read as a smile.
      ..drawArc(
        ring(0.05, 0.78, 0.98),
        angle - 2.3,
        1.3,
        false,
        stroke(ribbon(34, 0.8), 0.2, 0.11),
      )
      ..drawArc(
        ring(-0.72, -0.12, 0.86),
        angle - 0.5,
        1.0,
        false,
        stroke(ribbon(-38, 0.65), 0.16, 0.1),
      )
      ..drawArc(
        ring(0.38, -0.08, 0.4),
        angle + 3.5,
        1.3,
        false,
        stroke(Colors.white.withValues(alpha: 0.42 * energy), 0.08, 0.07),
      )
      // Its volume: darker towards the bottom right, whatever is inside.
      ..drawRect(
        sphere,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.35),
            radius: 1.05,
            colors: [
              const Color(0x00000000),
              const Color(0x00000000),
              Color.fromRGBO(0, 0, 0, lerpDouble(0.72, 0.5, playing)!),
            ],
            stops: const [0, 0.55, 1],
          ).createShader(sphere),
      )
      // The light it catches: a small sharp one, and its soft bloom.
      ..drawOval(
        Rect.fromCenter(
          center: center + Offset(-radius * 0.3, -radius * 0.5),
          width: radius * 0.7,
          height: radius * 0.36,
        ),
        soft(Colors.white.withValues(alpha: 0.32 * energy), 0.16),
      )
      ..drawOval(
        Rect.fromCenter(
          center: center + Offset(-radius * 0.36, -radius * 0.56),
          width: radius * 0.3,
          height: radius * 0.15,
        ),
        soft(Colors.white.withValues(alpha: 0.85 * energy), 0.04),
      )
      ..restore()
      // The rim, as the Now Playing lens has it.
      ..drawCircle(
        center,
        radius - 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xA6FFFFFF), Color(0x1AFFFFFF), Color(0x52FFFFFF)],
            stops: [0, 0.55, 1],
          ).createShader(sphere),
      );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.fromTop != fromTop ||
      old.fromEdge != fromEdge ||
      old.toTop != toTop ||
      old.toEdge != toEdge ||
      old.angleFrom != angleFrom ||
      old.angleTo != angleTo ||
      old.turn != turn ||
      old.live != live;
}
