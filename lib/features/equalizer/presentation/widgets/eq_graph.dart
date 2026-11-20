import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:troona/core/layout/app_layout.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/presentation/utils/eq_format.dart';

/// Where things go in the graph: bands across on a logarithmic frequency
/// scale (so the curve is true on any phone), gains up.
final class EqGraphGeometry {
  EqGraphGeometry(this.layout, Size size)
    : plot = Rect.fromLTRB(
        left,
        top,
        math.max(left + 1, size.width - right),
        math.max(top + 1, size.height - bottom),
      ) {
    final logs = [for (final b in layout.bands) math.log(b.centerHz)];
    final span = logs.length < 2 ? 1.0 : logs.last - logs.first;
    // Half a band's spacing on each side, so the end dots are not cut.
    final pad = logs.length < 2 ? 1.0 : span / (logs.length - 1) / 2;
    _lo = (logs.isEmpty ? 0 : logs.first) - pad;
    _hi = (logs.isEmpty ? 0 : logs.last) + pad;
  }

  final EqLayout layout;
  final Rect plot;
  late final double _lo;
  late final double _hi;

  /// Room for the gain labels, the value bubble and the frequencies.
  static const left = 34.0;
  static const top = 30.0;
  static const right = 10.0;
  static const bottom = 22.0;

  /// Gains closer to 0 than this snap to 0.
  static const snap = 0.5;

  double xOf(int band) =>
      plot.left +
      (math.log(layout.bands[band].centerHz) - _lo) / (_hi - _lo) * plot.width;

  double yOf(double db) =>
      plot.bottom -
      (db - layout.minDb) / (layout.maxDb - layout.minDb) * plot.height;

  /// The gain at height [y]: within the phone's range, by half decibels,
  /// snapped to 0 near it.
  double dbAt(double y) {
    final raw =
        layout.minDb +
        (plot.bottom - y) / plot.height * (layout.maxDb - layout.minDb);
    final db = layout.fit(raw);
    return db.abs() <= snap ? 0 : db;
  }

  /// The band closest to [x], across.
  int nearestBand(double x) {
    var best = 0;
    var distance = double.infinity;
    for (var i = 0; i < layout.bands.length; i++) {
      final d = (xOf(i) - x).abs();
      if (d < distance) {
        distance = d;
        best = i;
      }
    }
    return best;
  }

  /// The gain labels down the side: multiples of 6 dB (3 on a narrow
  /// range) within the range.
  List<double> get ticks {
    final range = layout.maxDb - layout.minDb;
    final step = range >= 18 ? 6.0 : 3.0;
    return [
      for (
        var db = (layout.minDb / step).ceil() * step;
        db <= layout.maxDb;
        db += step
      )
        db,
    ];
  }

  /// Under this much room per band, every other frequency is written.
  static const labelRoom = 40.0;

  bool get halfLabels =>
      layout.bands.length > 1 && plot.width / layout.bands.length < labelRoom;
}

/// The equalizer's curve, drawn with a finger: a touch sets the closest
/// band to the finger's height, a slide across sets every band it crosses.
/// A double tap on a band sets it back to 0. Each band is also a slider for
/// screen readers, so the graph works without the gesture.
///
/// The drawing never rebuilds the widget: a notifier repaints the canvas,
/// [onDraw] gets each frame's gains and [onCommit] the last ones; a touch
/// taken away calls [onCancel] instead.
class EqGraph extends StatefulWidget {
  const EqGraph({
    super.key,
    required this.layout,
    required this.gains,
    required this.enabled,
    required this.onDraw,
    required this.onCommit,
    required this.onCancel,
    required this.onBand,
    required this.bandLabel,
    required this.bandValue,
    this.comparing = false,
  });

  final EqLayout layout;
  final List<double> gains;

  /// False: the curve shows but takes no touch.
  final bool enabled;

  /// Drawn dashed: the music plays without it.
  final bool comparing;
  final ValueChanged<List<double>> onDraw;
  final ValueChanged<List<double>> onCommit;

  /// The touch was taken away: what was drawn is dropped.
  final VoidCallback onCancel;

  /// A band set by a screen reader.
  final void Function(int band, double db) onBand;

  /// What a screen reader reads for a band and for its gain.
  final String Function(double hz) bandLabel;
  final String Function(double db) bandValue;

  /// A second tap within this, on the same band, sets it to 0.
  static const doubleTapWindow = Duration(milliseconds: 300);

  @override
  State<EqGraph> createState() => _EqGraphState();
}

final class _Frame {
  const _Frame(this.gains, this.active);

  final List<double> gains;

  /// The band under the finger.
  final int? active;
}

class _EqGraphState extends State<EqGraph> {
  late final _frame = ValueNotifier(_Frame(widget.gains, null));
  Size _size = Size.zero;

  List<double>? _drawing;
  Offset? _last;
  Offset? _downAt;
  bool _moved = false;

  /// The band of the last tap, while a second one would make a double tap.
  int? _tapBand;
  Timer? _tapWindow;

  EqGraphGeometry get _geometry => EqGraphGeometry(widget.layout, _size);

  @override
  void didUpdateWidget(EqGraph old) {
    super.didUpdateWidget(old);
    if (old.layout != widget.layout) {
      _cancel();
    } else if (_drawing case final drawn? when !widget.enabled) {
      // Switched off under the finger: the recognizer goes without an end,
      // and what the phone heard is kept, after this build.
      _drawing = null;
      _last = null;
      final result = List<double>.unmodifiable(drawn);
      _frame.value = _Frame(result, null);
      final commit = widget.onCommit;
      scheduleMicrotask(() => commit(result));
      return;
    }
    if (_drawing == null) _frame.value = _Frame(widget.gains, null);
  }

  @override
  void dispose() {
    _tapWindow?.cancel();
    // Closed under the finger: what the phone heard is kept, once the tree
    // is no longer locked.
    if (_drawing case final drawn?) {
      final commit = widget.onCommit;
      final result = List<double>.unmodifiable(drawn);
      scheduleMicrotask(() => commit(result));
    }
    _frame.dispose();
    super.dispose();
  }

  void _onStart(DragStartDetails details) {
    if (!widget.enabled || widget.gains.length != widget.layout.bands.length) {
      return;
    }
    final at = details.localPosition;
    final geometry = _geometry;
    final band = geometry.nearestBand(at.dx);
    final gains = [...widget.gains];
    _set(gains, band, geometry.dbAt(at.dy));
    _drawing = gains;
    _last = at;
    _downAt = at;
    _moved = false;
    _frame.value = _Frame(List.unmodifiable(gains), band);
    widget.onDraw(List.unmodifiable(gains));
  }

  void _onUpdate(DragUpdateDetails details) {
    final gains = _drawing;
    final last = _last;
    if (gains == null || last == null) return;
    final at = details.localPosition;
    if ((at - _downAt!).distance > kTouchSlop) _moved = true;
    final geometry = _geometry;
    final previous = _frame.value.active;
    // Every band crossed since the last frame takes the height along the
    // finger's path, so a fast slide leaves no band behind.
    final lo = math.min(last.dx, at.dx), hi = math.max(last.dx, at.dx);
    for (var i = 0; i < gains.length; i++) {
      final x = geometry.xOf(i);
      if (x < lo || x > hi || hi == lo) continue;
      final t = (x - last.dx) / (at.dx - last.dx);
      _set(
        gains,
        i,
        geometry.dbAt(last.dy + (at.dy - last.dy) * t),
        quiet: true,
      );
    }
    final band = geometry.nearestBand(at.dx);
    final crossed = _set(gains, band, geometry.dbAt(at.dy), quiet: true);
    // One tick at most a frame: a new band, or the active one through 0.
    if (band != previous || crossed) AppHaptics.selectionClick();
    _last = at;
    _frame.value = _Frame(List.unmodifiable(gains), band);
    widget.onDraw(List.unmodifiable(gains));
  }

  void _onEnd(DragEndDetails _) {
    final gains = _drawing;
    if (gains == null) return;
    final band = _frame.value.active;
    _tapWindow?.cancel();
    if (!_moved && band != null && band == _tapBand) {
      gains[band] = 0;
      AppHaptics.selectionClick();
      _tapBand = null;
    } else if (!_moved && band != null) {
      _tapBand = band;
      _tapWindow = Timer(EqGraph.doubleTapWindow, () => _tapBand = null);
    } else {
      _tapBand = null;
    }
    _finish(gains);
  }

  /// The touch was taken away (a call, a system gesture): the curve goes
  /// back to what it was.
  void _cancel() {
    if (_drawing == null) return;
    _drawing = null;
    _last = null;
    _frame.value = _Frame(widget.gains, null);
    // Out of a build: a layout change cancels from didUpdateWidget.
    scheduleMicrotask(widget.onCancel);
  }

  void _finish(List<double> gains) {
    _drawing = null;
    _last = null;
    final result = List<double>.unmodifiable(gains);
    _frame.value = _Frame(result, null);
    widget.onCommit(result);
  }

  /// Sets [band] to [db]; true when that took it through 0 (ticks once,
  /// unless [quiet]: the caller ticks).
  bool _set(List<double> gains, int band, double db, {bool quiet = false}) {
    final before = gains[band];
    gains[band] = db;
    final crossed =
        before != db && (db == 0 || (before != 0 && before.sign != db.sign));
    if (crossed && !quiet) AppHaptics.selectionClick();
    return crossed;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scaler = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: AppLayout.maxTextScale);
    final format = EqFormat(Localizations.localeOf(context).toString());
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return Listener(
          // A cancel reaches the recognizer as an end: put the curve back
          // first. Listeners run before recognizers.
          onPointerCancel: (_) => _cancel(),
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            // Off, the graph takes no touch, and the sheet's drag works
            // over it.
            gestures: {
              if (widget.enabled)
                _EagerPanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      _EagerPanGestureRecognizer
                    >(_EagerPanGestureRecognizer.new, (recognizer) {
                      recognizer
                        ..onStart = _onStart
                        ..onUpdate = _onUpdate
                        ..onEnd = _onEnd
                        ..onCancel = _cancel;
                    }),
            },
            child: RepaintBoundary(
              child: CustomPaint(
                size: constraints.biggest,
                painter: _EqPainter(
                  frame: _frame,
                  layout: widget.layout,
                  comparing: widget.comparing,
                  enabled: widget.enabled,
                  accent: colors.accent,
                  accentForeground: colors.accentForeground,
                  grid: colors.hairline,
                  label: colors.labelTertiary,
                  dotRing: colors.bgSecondary,
                  scaler: scaler,
                  format: format,
                  bandLabel: widget.bandLabel,
                  bandValue: widget.bandValue,
                  onBand: widget.onBand,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EqPainter extends CustomPainter {
  _EqPainter({
    required this.frame,
    required this.layout,
    required this.comparing,
    required this.enabled,
    required this.accent,
    required this.accentForeground,
    required this.grid,
    required this.label,
    required this.dotRing,
    required this.scaler,
    required this.format,
    required this.bandLabel,
    required this.bandValue,
    required this.onBand,
  }) : super(repaint: frame);

  final ValueNotifier<_Frame> frame;
  final EqLayout layout;
  final bool comparing;
  final bool enabled;
  final Color accent;
  final Color accentForeground;
  final Color grid;
  final Color label;
  final Color dotRing;
  final TextScaler scaler;
  final EqFormat format;
  final String Function(double hz) bandLabel;
  final String Function(double db) bandValue;
  final void Function(int band, double db) onBand;

  static const _labelSize = 11.0;
  static const _dot = 5.0;
  static const _activeDot = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final g = EqGraphGeometry(layout, size);
    final gains = frame.value.gains;
    final active = frame.value.active;
    _paintGrid(canvas, g);
    if (gains.length != layout.bands.length || gains.isEmpty) return;
    final points = [
      for (var i = 0; i < gains.length; i++) Offset(g.xOf(i), g.yOf(gains[i])),
    ];
    final curve = _curve(points, g.plot);
    if (!comparing) _paintFill(canvas, g, curve);
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    if (comparing) {
      _paintDashed(canvas, curve, stroke..color = accent.withValues(alpha: .6));
    } else {
      canvas.drawPath(curve, stroke);
    }
    for (var i = 0; i < points.length; i++) {
      final r = i == active ? _activeDot : _dot;
      canvas
        ..drawCircle(points[i], r + 2, Paint()..color = dotRing)
        ..drawCircle(points[i], r, Paint()..color = accent);
    }
    if (active != null) _paintBubble(canvas, g, points[active], gains[active]);
  }

  void _paintGrid(Canvas canvas, EqGraphGeometry g) {
    final zero = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final faint = Paint()
      ..color = grid.withValues(alpha: grid.a * .45)
      ..strokeWidth = 1;
    for (final db in g.ticks) {
      final y = g.yOf(db);
      if (db == 0) {
        canvas.drawLine(Offset(g.plot.left, y), Offset(g.plot.right, y), zero);
      } else {
        _dashedLine(
          canvas,
          Offset(g.plot.left, y),
          Offset(g.plot.right, y),
          faint,
        );
      }
      _text(
        canvas,
        format.gain(db),
        Offset(g.plot.left - 6, y),
        align: Alignment.centerRight,
      );
    }
    for (var i = 0; i < layout.bands.length; i++) {
      if (g.halfLabels && i.isOdd) continue;
      _text(
        canvas,
        format.shortHz(layout.bands[i].centerHz),
        Offset(g.xOf(i), g.plot.bottom + 6),
        align: Alignment.topCenter,
      );
    }
  }

  /// A smooth curve through [points] that never overshoots between two of
  /// them (monotone cubic, Fritsch-Carlson), flat out to the plot's edges.
  static Path _curve(List<Offset> points, Rect plot) {
    final path = Path()
      ..moveTo(plot.left, points.first.dy)
      ..lineTo(points.first.dx, points.first.dy);
    if (points.length == 1) return path..lineTo(plot.right, points.first.dy);
    final n = points.length;
    final slopes = [
      for (var i = 0; i < n - 1; i++)
        (points[i + 1].dy - points[i].dy) / (points[i + 1].dx - points[i].dx),
    ];
    final tangents = List<double>.filled(n, 0);
    tangents[0] = slopes.first;
    tangents[n - 1] = slopes.last;
    for (var i = 1; i < n - 1; i++) {
      final a = slopes[i - 1], b = slopes[i];
      tangents[i] = a * b <= 0 ? 0 : 2 / (1 / a + 1 / b);
    }
    // Flat ends: the curve carries on level beyond the outer bands.
    tangents[0] = 0;
    tangents[n - 1] = 0;
    for (var i = 0; i < n - 1; i++) {
      final p = points[i], q = points[i + 1];
      final h = q.dx - p.dx;
      path.cubicTo(
        p.dx + h / 3,
        p.dy + tangents[i] * h / 3,
        q.dx - h / 3,
        q.dy - tangents[i + 1] * h / 3,
        q.dx,
        q.dy,
      );
    }
    return path..lineTo(plot.right, points.last.dy);
  }

  /// What is added above 0 dB and taken away below it, fading towards the
  /// line.
  void _paintFill(Canvas canvas, EqGraphGeometry g, Path curve) {
    final zeroY = g.yOf(0).clamp(g.plot.top, g.plot.bottom);
    final area = Path.from(curve)
      ..lineTo(g.plot.right, zeroY)
      ..lineTo(g.plot.left, zeroY)
      ..close();
    final strong = accent.withValues(alpha: .24);
    final faint = accent.withValues(alpha: .03);
    final above = Rect.fromLTRB(g.plot.left, g.plot.top, g.plot.right, zeroY);
    final below = Rect.fromLTRB(
      g.plot.left,
      zeroY,
      g.plot.right,
      g.plot.bottom,
    );
    for (final (rect, from) in [(above, above.top), (below, below.bottom)]) {
      if (rect.height <= 0) continue;
      canvas
        ..save()
        ..clipRect(rect)
        ..drawPath(
          area,
          Paint()
            ..shader = ui.Gradient.linear(Offset(0, from), Offset(0, zeroY), [
              strong,
              faint,
            ]),
        )
        ..restore();
    }
  }

  void _paintDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 5, metric.length)),
          paint,
        );
      }
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    for (var x = a.dx; x < b.dx; x += 6) {
      canvas.drawLine(
        Offset(x, a.dy),
        Offset(math.min(x + 2, b.dx), b.dy),
        paint,
      );
    }
  }

  /// The gain of the band under the finger, above its dot (below it near
  /// the top).
  void _paintBubble(Canvas canvas, EqGraphGeometry g, Offset at, double db) {
    final painter = TextPainter(
      text: TextSpan(
        text: '${format.gain(db)} dB',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accentForeground,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final w = painter.width + 14, h = painter.height + 6;
    var top = at.dy - _activeDot - 8 - h;
    if (top < 0) top = at.dy + _activeDot + 8;
    final left = (at.dx - w / 2)
        .clamp(0.0, math.max(0.0, g.plot.right - w))
        .toDouble();
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      Radius.circular(h / 2),
    );
    canvas.drawRRect(box, Paint()..color = accent);
    painter.paint(canvas, Offset(left + 7, top + 3));
  }

  void _text(
    Canvas canvas,
    String text,
    Offset anchor, {
    required Alignment align,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: _labelSize,
          fontWeight: FontWeight.w500,
          color: label,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final dx = switch (align) {
      Alignment.centerRight => anchor.dx - painter.width,
      _ => anchor.dx - painter.width / 2,
    };
    final dy = align == Alignment.topCenter
        ? anchor.dy
        : anchor.dy - painter.height / 2;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final g = EqGraphGeometry(layout, size);
    final gains = frame.value.gains;
    if (gains.length != layout.bands.length) return const [];
    final width = g.plot.width / math.max(1, layout.bands.length);
    String value(double db) => bandValue(db);
    return [
      for (var i = 0; i < gains.length; i++)
        CustomPainterSemantics(
          key: ValueKey('band$i'),
          rect: Rect.fromCenter(
            center: Offset(g.xOf(i), g.plot.center.dy),
            width: width,
            height: g.plot.height,
          ),
          properties: SemanticsProperties(
            enabled: enabled,
            label: bandLabel(layout.bands[i].centerHz),
            value: value(gains[i]),
            increasedValue: value(layout.fit(gains[i] + 1)),
            decreasedValue: value(layout.fit(gains[i] - 1)),
            textDirection: TextDirection.ltr,
            onIncrease: enabled
                ? () => onBand(i, layout.fit(gains[i] + 1))
                : null,
            onDecrease: enabled
                ? () => onBand(i, layout.fit(gains[i] - 1))
                : null,
          ),
        ),
    ];
  };

  @override
  bool shouldRepaint(_EqPainter old) =>
      old.frame != frame ||
      old.layout != layout ||
      old.comparing != comparing ||
      old.enabled != enabled ||
      old.accent != accent ||
      old.scaler != scaler;

  @override
  bool shouldRebuildSemantics(_EqPainter old) =>
      shouldRepaint(old) || old.bandLabel != bandLabel;
}

/// Takes the pointer on touch-down, so the sheet's drag to close and its
/// scrolling cannot win while the finger draws.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
