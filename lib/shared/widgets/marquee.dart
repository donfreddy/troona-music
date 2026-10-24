import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Single line of text that scrolls when, and only when, it does not fit.
///
/// Fitting text is a plain [Text], placed by [alignment]: no ticker, no
/// layer. Overflowing text loops seamlessly: it rests for [pause], then
/// travels until a copy placed [gap] after it reaches the start, at a
/// steady [velocity] with short ramps at both ends. The edges fade out;
/// the leading one only while the text is away from its resting place.
///
/// Every frame is a repaint of one [CustomPaint] behind a
/// [RepaintBoundary]: no rebuild, no relayout, and nothing ticks during
/// the pause. With reduced motion, the text is ellipsized instead.
class Marquee extends StatefulWidget {
  final String text;
  final TextStyle? style;

  /// Scrolling speed in logical pixels per second.
  final double velocity;

  /// Rest at the start of each loop.
  final Duration pause;

  /// Space between the text and its copy.
  final double gap;

  /// Width of the edge fades.
  final double fadeWidth;

  /// Where fitting text sits.
  final AlignmentGeometry alignment;

  const Marquee({
    super.key,
    required this.text,
    this.style,
    this.velocity = 32,
    this.pause = const Duration(seconds: 2),
    this.gap = 40,
    this.fadeWidth = 16,
    this.alignment = AlignmentDirectional.centerStart,
  }) : assert(velocity > 0);

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this)
    ..addStatusListener(_onStatus);
  Timer? _pauseTimer;

  /// Laid out once per text, style, scale and direction: not per frame.
  TextPainter? _painter;
  (String, TextStyle, TextScaler, TextDirection)? _painterKey;

  /// Whether the loop should run, as of the last layout.
  bool _scrolling = false;

  @override
  void didUpdateWidget(Marquee old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.style != widget.style) _restart();
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.dispose();
    _painter?.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // The copy now sits exactly where the text started: going back to 0
    // draws the same frame, then the next loop rests first.
    _controller.value = 0;
    _schedule();
  }

  void _schedule() {
    _pauseTimer?.cancel();
    _pauseTimer = Timer(widget.pause, () {
      if (mounted && _scrolling) _controller.forward(from: 0);
    });
  }

  /// Back to the resting place; the next layout decides whether to loop.
  void _restart() {
    _pauseTimer?.cancel();
    _controller.stop();
    _controller.value = 0;
    _scrolling = false;
  }

  /// Starts or stops the loop after layout found the text (not) fitting.
  /// Deferred: layout is no place to touch the controller.
  void _sync(bool overflows, double period) {
    if (overflows == _scrolling) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || overflows == _scrolling) return;
      _scrolling = overflows;
      if (overflows) {
        _controller.duration = Duration(
          microseconds: (period / widget.velocity * 1e6).round(),
        );
        _schedule();
      } else {
        _restart();
      }
    });
  }

  TextPainter _layoutText(TextStyle style, TextScaler scaler, TextDirection d) {
    final key = (widget.text, style, scaler, d);
    if (key == _painterKey) return _painter!;
    _painter?.dispose();
    _painterKey = key;
    return _painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: d,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = _layoutText(style, scaler, direction);
        final width = constraints.maxWidth;
        // Half a pixel of slack: rounding alone must not start a loop.
        final overflows =
            !reduceMotion && width.isFinite && painter.width > width + 0.5;
        final period = painter.width + widget.gap;
        _sync(overflows, period);

        if (!overflows) {
          final text = Text(
            widget.text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          );
          return width.isFinite
              ? SizedBox(
                  width: width,
                  child: Align(alignment: widget.alignment, child: text),
                )
              : text;
        }

        return Semantics(
          label: widget.text,
          textDirection: direction,
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(width, painter.height),
              painter: _MarqueePainter(
                text: painter,
                progress: _controller,
                curve: _Ramp.over(period / widget.velocity),
                period: period,
                fadeWidth: math.min(widget.fadeWidth, width / 4),
                rtl: direction == TextDirection.rtl,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints the text and its copy shifted by [progress] of a [period], then
/// fades the edges in the same layer.
class _MarqueePainter extends CustomPainter {
  final TextPainter text;

  /// Linear run time; [curve] turns it into distance. Not a
  /// [CurvedAnimation]: one per layout would each stay subscribed to the
  /// controller.
  final Animation<double> progress;
  final Curve curve;
  final double period;
  final double fadeWidth;
  final bool rtl;

  _MarqueePainter({
    required this.text,
    required this.progress,
    required this.curve,
    required this.period,
    required this.fadeWidth,
    required this.rtl,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final shift = curve.transform(progress.value) * period;
    final bounds = Offset.zero & size;
    final y = (size.height - text.height) / 2;

    canvas
      ..clipRect(bounds)
      ..saveLayer(bounds, Paint());
    for (final x in [-shift, period - shift]) {
      text.paint(canvas, Offset(rtl ? size.width - text.width - x : x, y));
    }

    // The trailing edge always fades: more text follows. The leading one
    // fades in as the text leaves, and out as the copy comes to rest.
    final leading = math.min(math.min(shift, period - shift), fadeWidth);
    final leadingAlpha = 1 - leading / fadeWidth;
    final edge = fadeWidth / size.width;
    final colors = [
      Colors.black.withValues(alpha: leadingAlpha),
      Colors.black,
      Colors.black,
      Colors.transparent,
    ];
    canvas
      ..drawRect(
        bounds,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            colors: rtl ? colors.reversed.toList() : colors,
            stops: [0, edge, 1 - edge, 1],
          ).createShader(bounds),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_MarqueePainter old) =>
      old.text != text ||
      old.period != period ||
      old.fadeWidth != fadeWidth ||
      old.rtl != rtl ||
      old.curve != curve;
}

/// Constant speed with an acceleration at the start and a deceleration at
/// the end, each lasting [_ramp] of the run. The speed never jumps: the
/// text eases off its resting place and back into it.
class _Ramp extends Curve {
  final double _ramp;

  const _Ramp(this._ramp) : assert(_ramp > 0 && _ramp <= 0.5);

  /// About 400 ms of ramp, whatever the run lasts.
  factory _Ramp.over(double seconds) =>
      _Ramp((0.4 / math.max(seconds, 0.8)).clamp(0.05, 0.5));

  @override
  double transformInternal(double t) {
    final r = _ramp;
    // Trapezoidal speed: peak 1 / (1 - r), reached after r.
    final peak = 1 / (1 - r);
    if (t < r) return peak * t * t / (2 * r);
    if (t > 1 - r) return 1 - peak * (1 - t) * (1 - t) / (2 * r);
    return peak * (t - r / 2);
  }
}
