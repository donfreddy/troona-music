import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/glass_lens.dart';

/// Gap left free around the time label at the bottom of the ring, per side.
const double _kLabelGap = GlassLens.labelGap;

/// The arc starts just left of the label (6 o'clock) and runs clockwise, up
/// the left side, as in the reference.
const double _kStartAngle = math.pi / 2 + _kLabelGap;
const double _kMaxSweep = 2 * math.pi - 2 * _kLabelGap;

/// Elapsed-time arc drawn on the [GlassLens] hairline, with circular seek.
///
/// Dragging on the glass band scrubs along the circle: a soft icy glow
/// follows the finger, the remaining time updates live, and a selection
/// haptic ticks every second. The seek is sent once, on release.
///
/// Repaints are driven by [progress] directly, so playback ticks never
/// rebuild widgets; the label only rebuilds when its second changes.
class ProgressRing extends StatefulWidget {
  final double diameter;

  /// Diameter of the clear centre; touches inside it are left to the
  /// carousel underneath (swipes start on the artwork).
  final double holeDiameter;

  final ValueListenable<PlaybackProgress> progress;
  final ValueChanged<Duration> onSeek;

  const ProgressRing({
    super.key,
    required this.diameter,
    required this.holeDiameter,
    required this.progress,
    required this.onSeek,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  /// Scrub position in `[0, 1]` once the finger has moved, null otherwise.
  final ValueNotifier<double?> _scrub = ValueNotifier(null);

  /// Elapsed ratio quantised to half a pixel of arc, or -1 while the
  /// duration is unknown. The painter listens to this instead of the raw
  /// 60 fps clock, so the frame (and the lens blur beneath it) is only
  /// recomposited when the arc visibly moves.
  final ValueNotifier<double> _arc = ValueNotifier(-1);

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  /// Duration captured on touch-down; null when no scrub is in progress.
  /// A different duration mid-gesture means the track changed: abort.
  Duration? _scrubDuration;
  double _startRatio = 0;
  bool _moved = false;

  int? _lastTickSecond;
  final Stopwatch _tickClock = Stopwatch()..start();
  int _lastTickMs = -1000;

  /// Minimum spacing between haptic ticks: one platform call per frame on
  /// long tracks would be a storm.
  static const int _minTickIntervalMs = 50;

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_onProgress);
    _onProgress();
  }

  @override
  void didUpdateWidget(ProgressRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      old.progress.removeListener(_onProgress);
      widget.progress.addListener(_onProgress);
    }
    _onProgress();
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgress);
    _scrub.dispose();
    _arc.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _onProgress() {
    final progress = widget.progress.value;
    if (_scrubDuration != null && progress.duration != _scrubDuration) {
      _reset();
    }
    if (progress.duration <= Duration.zero) {
      _arc.value = -1;
      return;
    }
    final arcLength =
        widget.diameter / 2 * GlassLens.hairlineFraction * _kMaxSweep;
    final step = arcLength <= 0 ? 1.0 : 0.5 / arcLength;
    _arc.value = ((progress.ratio / step).round() * step).clamp(0.0, 1.0);
  }

  /// Ratio under [local], or null inside the label gap.
  double? _ratioAt(Offset local) {
    final radius = widget.diameter / 2;
    final vector = local - Offset(radius, radius);
    var angle =
        (math.atan2(vector.dy, vector.dx) - _kStartAngle) % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;
    return angle <= _kMaxSweep ? angle / _kMaxSweep : null;
  }

  void _onStart(DragStartDetails details) {
    final duration = widget.progress.value.duration;
    if (duration <= Duration.zero) return;
    // Touching the time label must not jump to either end of the track.
    final ratio = _ratioAt(details.localPosition);
    if (ratio == null) return;
    _scrubDuration = duration;
    _startRatio = ratio;
    _moved = false;
    _lastTickSecond = _secondAt(ratio);
    _glow.forward();
  }

  void _onUpdate(DragUpdateDetails details) {
    if (_scrubDuration == null) return;
    final current = _scrub.value ?? _startRatio;
    final angleRatio = _ratioAt(details.localPosition);
    // Dragged into the label gap: hold at the closest end of the arc.
    final next = angleRatio ?? (current > 0.5 ? 1.0 : 0.0);
    // Crossing the gap would teleport between start and end.
    if ((next - current).abs() > 0.5) return;
    _moved = true;
    _scrub.value = next;

    final second = _secondAt(next);
    final now = _tickClock.elapsedMilliseconds;
    if (second != _lastTickSecond && now - _lastTickMs >= _minTickIntervalMs) {
      _lastTickSecond = second;
      _lastTickMs = now;
      unawaited(AppHaptics.selectionClick());
    }
  }

  void _onEnd(DragEndDetails _) {
    final ratio = _scrub.value;
    final duration = _scrubDuration;
    // A plain tap on the ring is not a seek: only a real scrub commits.
    final commit = _moved && ratio != null && duration != null;
    _reset();
    if (commit) {
      widget.onSeek(
        Duration(milliseconds: (duration.inMilliseconds * ratio).round()),
      );
    }
  }

  /// Ends the scrub without seeking (cancel, track change, tap).
  void _reset() {
    _scrubDuration = null;
    _moved = false;
    _scrub.value = null;
    _glow.reverse();
  }

  int _secondAt(double ratio) =>
      ((_scrubDuration ?? widget.progress.value.duration).inMilliseconds *
          ratio) ~/
      1000;

  void _seekBy(Duration delta) {
    final progress = widget.progress.value;
    if (progress.duration <= Duration.zero) return;
    final target = progress.position + delta;
    widget.onSeek(
      target < Duration.zero
          ? Duration.zero
          : (target > progress.duration ? progress.duration : target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final holeFraction = widget.holeDiameter / widget.diameter;

    return _SeekSemantics(
      progress: widget.progress,
      onIncrease: () => _seekBy(const Duration(seconds: 10)),
      onDecrease: () => _seekBy(const Duration(seconds: -10)),
      child: SizedBox.square(
        dimension: widget.diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(widget.diameter),
                  painter: _RingPainter(
                    arc: _arc,
                    scrub: _scrub,
                    glow: _glow,
                    holeFraction: holeFraction,
                    start: colors.progressStart,
                    end: colors.progressEnd,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom:
                  widget.diameter / 2 * (1 - GlassLens.hairlineFraction) - 9,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: _RemainingLabel(
                    progress: widget.progress,
                    scrub: _scrub,
                  ),
                ),
              ),
            ),
            // Touch band: the clip restricts hit testing to the glass ring.
            ClipPath(
              clipper: _BandClipper(holeFraction),
              // Pointer cancel (incoming call, system gesture) reaches the
              // recognizer as an end: clear the scrub first so it is not
              // committed. Listeners run before gesture recognizers.
              child: Listener(
                onPointerCancel: (_) => _reset(),
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _EagerPanGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          _EagerPanGestureRecognizer
                        >(_EagerPanGestureRecognizer.new, (recognizer) {
                          recognizer
                            ..onStart = _onStart
                            ..onUpdate = _onUpdate
                            ..onEnd = _onEnd
                            ..onCancel = _reset;
                        }),
                  },
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exposes the ring as a slider to screen readers (the only seek control
/// on the full player). Rebuilt only when the announced second changes.
class _SeekSemantics extends StatefulWidget {
  final ValueListenable<PlaybackProgress> progress;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final Widget child;

  const _SeekSemantics({
    required this.progress,
    required this.onIncrease,
    required this.onDecrease,
    required this.child,
  });

  @override
  State<_SeekSemantics> createState() => _SeekSemanticsState();
}

class _SeekSemanticsState extends State<_SeekSemantics> {
  int _second = -1;

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_refresh);
    _second = widget.progress.value.position.inSeconds;
  }

  @override
  void didUpdateWidget(_SeekSemantics old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      old.progress.removeListener(_refresh);
      widget.progress.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.progress.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    final second = widget.progress.value.position.inSeconds;
    if (second != _second) setState(() => _second = second);
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.value;
    String at(Duration d) => d.toMMSS();
    const step = Duration(seconds: 10);
    final up = progress.position + step;
    final down = progress.position - step;
    return Semantics(
      container: true,
      slider: true,
      label: 'Playback position',
      value: '${at(progress.position)} of ${at(progress.duration)}',
      increasedValue: at(up > progress.duration ? progress.duration : up),
      decreasedValue: at(down.isNegative ? Duration.zero : down),
      onIncrease: widget.onIncrease,
      onDecrease: widget.onDecrease,
      child: widget.child,
    );
  }
}

/// Claims the pointer on touch-down so the page's vertical drag-to-dismiss
/// cannot win while the user scrubs along the left side of the ring.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _BandClipper extends CustomClipper<Path> {
  final double holeFraction;

  const _BandClipper(this.holeFraction);

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..addOval(Rect.fromCircle(center: center, radius: radius * holeFraction));
  }

  @override
  bool shouldReclip(_BandClipper oldClipper) =>
      oldClipper.holeFraction != holeFraction;
}

/// Remaining time, rebuilt only when the displayed second changes.
class _RemainingLabel extends StatefulWidget {
  final ValueListenable<PlaybackProgress> progress;
  final ValueListenable<double?> scrub;

  const _RemainingLabel({required this.progress, required this.scrub});

  @override
  State<_RemainingLabel> createState() => _RemainingLabelState();
}

class _RemainingLabelState extends State<_RemainingLabel> {
  late String _text = _compute();

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_refresh);
    widget.scrub.addListener(_refresh);
  }

  @override
  void didUpdateWidget(_RemainingLabel old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      old.progress.removeListener(_refresh);
      widget.progress.addListener(_refresh);
    }
    if (old.scrub != widget.scrub) {
      old.scrub.removeListener(_refresh);
      widget.scrub.addListener(_refresh);
    }
    _refresh();
  }

  @override
  void dispose() {
    widget.progress.removeListener(_refresh);
    widget.scrub.removeListener(_refresh);
    super.dispose();
  }

  String _compute() {
    final progress = widget.progress.value;
    final scrub = widget.scrub.value;
    final position = scrub == null
        ? progress.position
        : progress.duration * scrub;
    final remaining = progress.duration - position;
    if (remaining <= Duration.zero) return Duration.zero.toMMSS();
    // Rounded up, as players do: a fresh 3:20 track reads 3:20, not 3:19.
    return Duration(seconds: (remaining.inMilliseconds / 1000).ceil()).toMMSS();
  }

  void _refresh() {
    final next = _compute();
    if (next != _text) setState(() => _text = next);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: .8),
        fontSize: 13,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  /// Quantised elapsed ratio, -1 while the duration is unknown.
  final ValueListenable<double> arc;
  final ValueListenable<double?> scrub;
  final Animation<double> glow;
  final double holeFraction;
  final Color start;
  final Color end;

  _RingPainter({
    required this.arc,
    required this.scrub,
    required this.glow,
    required this.holeFraction,
    required this.start,
    required this.end,
  }) : super(repaint: Listenable.merge([arc, scrub, glow]));

  @override
  void paint(Canvas canvas, Size size) {
    if (arc.value < 0) return;

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final arcRadius = radius * GlassLens.hairlineFraction;
    final ratio = scrub.value ?? arc.value;
    final sweep = math.max(ratio * _kMaxSweep, 0.001);
    final headAngle = _kStartAngle + sweep;
    Offset onCircle(double r) =>
        center + Offset(math.cos(headAngle), math.sin(headAngle)) * r;

    // Touch glow: lights the glass around the finger while scrubbing.
    if (glow.value > 0) {
      final glowCenter = onCircle(radius * (1 + holeFraction) / 2);
      final glowRadius = radius * 0.38;
      canvas
        ..save()
        ..clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addOval(Rect.fromCircle(center: center, radius: radius))
            ..addOval(
              Rect.fromCircle(center: center, radius: radius * holeFraction),
            ),
        )
        ..drawCircle(
          glowCenter,
          glowRadius,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    start.withValues(alpha: 0.5 * glow.value),
                    start.withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromCircle(center: glowCenter, radius: glowRadius),
                ),
        )
        ..restore();
    }

    final arcRect = Rect.fromCircle(center: center, radius: arcRadius);
    canvas.drawArc(
      arcRect,
      _kStartAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        // Butt cap: a round tail cap would sit before the gradient start and
        // wrap to the bright end colour. The head dot rounds the other end.
        ..strokeCap = StrokeCap.butt
        ..shader = SweepGradient(
          endAngle: sweep,
          colors: [start.withValues(alpha: 0.35), start, end],
          stops: const [0, 0.7, 1],
          transform: const GradientRotation(_kStartAngle),
        ).createShader(arcRect),
    );

    // Bright head with a soft halo.
    final head = onCircle(arcRadius);
    canvas
      ..drawCircle(
        head,
        6,
        Paint()
          ..color = start.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(head, 2.5, Paint()..color = end);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.arc != arc ||
      oldDelegate.scrub != scrub ||
      oldDelegate.glow != glow ||
      oldDelegate.holeFraction != holeFraction ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}
