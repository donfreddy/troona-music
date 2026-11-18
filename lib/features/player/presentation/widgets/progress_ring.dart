import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:troona/core/extensions/duration_ext.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/core/utils/haptics_helper.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/glass_lens.dart';
import 'package:troona/core/extensions/context_ext.dart';

/// Gap left free around the time label at the bottom of the ring, per side.
const double _kLabelGap = GlassLens.labelGap;

/// The arc starts just left of the label (6 o'clock) and runs clockwise, up
/// the left side, as in the reference.
const double _kStartAngle = math.pi / 2 + _kLabelGap;
const double _kMaxSweep = 2 * math.pi - 2 * _kLabelGap;

/// What a finger on the ring does, each 0 to 1: how wide the band is, how
/// lit, and how far the ring is lifted.
typedef RingPress = ({double widen, double light, double lift});

/// Elapsed-time arc drawn on the [GlassLens] hairline, with circular seek.
///
/// A finger on the glass band turns the progress into the band itself: the
/// thin arc widens to fill it, lights up as diffuse light, brightest at
/// the head, and the lens grows a little ([lift]). Dragging scrubs along
/// the circle, the remaining time updates live, and a selection haptic
/// ticks every second. The seek is sent once, on release; then the light
/// goes first and the band narrows back to the arc.
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

  /// Written with how far the ring is lifted under the finger, 0 to 1
  /// (eased), for the lens drawn under it by the stage. Stays 0 when the
  /// phone asks for less motion: the band still widens, nothing grows.
  final ValueNotifier<double>? lift;

  const ProgressRing({
    super.key,
    required this.diameter,
    required this.holeDiameter,
    required this.progress,
    required this.onSeek,
    this.lift,
  });

  /// Press in, the reference's 220 ms; release, its 240 ms.
  static const pressDuration = Duration(milliseconds: 220);
  static const releaseDuration = Duration(milliseconds: 240);

  /// While the finger is down: the band widens over the first 70 % of
  /// the press, fast at first...
  static const Curve widenCurve = Interval(0, 0.7, curve: Curves.easeOutCubic);

  /// ...the light comes over the last 40 %, once the band is wide...
  static const Curve lightCurve = Interval(0.6, 1, curve: Curves.easeOut);

  /// ...and the ring rises fast and settles.
  static const Curve liftCurve = Curves.easeOutCubic;

  /// Share of the release the light takes to go out; the band holds its
  /// width until then.
  static const double lightOffShare = 0.4;

  /// The effects at [press] (0 to 1) while a finger is down.
  @visibleForTesting
  static RingPress pressedAt(double press) {
    final t = press.clamp(0.0, 1.0);
    return (
      widen: widenCurve.transform(t),
      light: lightCurve.transform(t),
      lift: liftCurve.transform(t),
    );
  }

  /// The effects at [release] (0 to 1) after a release that found them at
  /// [from]. Each goes from where it was, whenever the finger left (a
  /// release played as the press backwards would end at full speed): the
  /// light goes out first, then the band narrows, and everything slows
  /// into rest. The ring starts back at once.
  @visibleForTesting
  static RingPress releasedAt(double release, RingPress from) {
    final r = release.clamp(0.0, 1.0);
    const settle = Curves.easeOutCubic;
    final hold = from.light > 0 ? lightOffShare : 0.0;
    return (
      light:
          from.light *
          (1 - Curves.easeOut.transform((r / lightOffShare).clamp(0.0, 1.0))),
      widen:
          from.widen *
          (1 - settle.transform(((r - hold) / (1 - hold)).clamp(0.0, 1.0))),
      lift: from.lift * (1 - settle.transform(r)),
    );
  }

  /// Stroke width and radius of the arc for [widen] (0 the 2.5 px arc on
  /// the hairline, 1 the whole glass band, hole edge to rim), for a ring
  /// of [radius] whose hole is [holeFraction] of it.
  @visibleForTesting
  static ({double width, double radius}) strokeAt(
    double widen, {
    required double radius,
    required double holeFraction,
  }) {
    final t = widen.clamp(0.0, 1.0);
    return (
      width: lerpDouble(2.5, radius * (1 - holeFraction), t)!,
      // The hairline sits off the middle of the band: recentre as it
      // widens, or the wide band would spill over one side.
      radius: lerpDouble(
        radius * GlassLens.hairlineFraction,
        radius * (1 + holeFraction) / 2,
        t,
      )!,
    );
  }

  /// How dense the band is across the glass, from the ring's centre out,
  /// at [widen]: whole against the cover, thinning out to nothing before
  /// the rim, as light seen through the glass (measured on the reference:
  /// two thirds a third of the way out, under half past the middle, gone
  /// at four fifths). The thin arc at rest is whole: the falloff comes as
  /// the band widens. Used as a mask, so only the alphas matter.
  @visibleForTesting
  static RadialGradient bandFalloff(
    double widen, {
    required double holeFraction,
  }) {
    final t = widen.clamp(0.0, 1.0);
    final band = 1 - holeFraction;
    Color dense(double alpha) =>
        Colors.white.withValues(alpha: lerpDouble(1, alpha, t));
    return RadialGradient(
      colors: [
        dense(1),
        dense(1),
        dense(0.68),
        dense(0.4),
        dense(0.04),
        dense(0),
      ],
      stops: [
        0,
        holeFraction,
        holeFraction + band * 0.35,
        holeFraction + band * 0.6,
        holeFraction + band * 0.82,
        1,
      ],
    );
  }

  /// The head's colour at [widen]: [end] on the thin arc, most of the way
  /// back to [start] on the band, where a wedge of plain white under the
  /// finger would glare (the reference's head is a light blue).
  @visibleForTesting
  static Color headColor(
    double widen, {
    required Color start,
    required Color end,
  }) => Color.lerp(end, start, 0.6 * widen.clamp(0.0, 1.0))!;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with TickerProviderStateMixin {
  /// Scrub position in `[0, 1]` once the finger has moved, null otherwise.
  final ValueNotifier<double?> _scrub = ValueNotifier(null);

  /// Elapsed ratio quantised to half a pixel of arc, or -1 while the
  /// duration is unknown. The painter listens to this instead of the raw
  /// 60 fps clock, so the frame (and the lens blur beneath it) is only
  /// recomposited when the arc visibly moves.
  final ValueNotifier<double> _arc = ValueNotifier(-1);

  /// 0 to 1 while a finger is down.
  late final AnimationController _press;

  /// 0 to 1 after it left, from [_releasedFrom].
  late final AnimationController _release;

  /// The effects when the finger left; null unless releasing.
  RingPress? _releasedFrom;

  /// The effects when a finger came back mid-release: width and light do
  /// not drop below them while it rises again. Null from rest.
  RingPress? _pressFrom;

  /// For the painter: the band's width and its light, 0 to 1.
  final ValueNotifier<double> _widen = ValueNotifier(0);
  final ValueNotifier<double> _light = ValueNotifier(0);

  /// Lift of the arc and the label, written to [ProgressRing.lift] for the
  /// lens; 0 with reduced motion.
  final ValueNotifier<double> _lift = ValueNotifier(0);
  bool _reduceMotion = false;

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
    _press = AnimationController(
      vsync: this,
      duration: ProgressRing.pressDuration,
    )..addListener(_onPress);
    _release =
        AnimationController(vsync: this, duration: ProgressRing.releaseDuration)
          ..addListener(_onPress)
          ..addStatusListener((status) {
            if (!status.isCompleted) return;
            _releasedFrom = null;
            _pressFrom = null;
            _press.value = 0;
          });
    widget.progress.addListener(_onProgress);
    _onProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _onPress();
  }

  @override
  void didUpdateWidget(ProgressRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      old.progress.removeListener(_onProgress);
      widget.progress.addListener(_onProgress);
    }
    if (old.lift != widget.lift) _resetLift(old.lift);
    _onProgress();
    _onPress();
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgress);
    // Gone mid-press (the stage left out on a tiny window): do not leave
    // the lens lifted.
    _resetLift(widget.lift);
    _scrub.dispose();
    _arc.dispose();
    _press.dispose();
    _release.dispose();
    _widen.dispose();
    _light.dispose();
    _lift.dispose();
    super.dispose();
  }

  RingPress get _effects {
    final released = _releasedFrom;
    if (released != null) {
      return ProgressRing.releasedAt(_release.value, released);
    }
    final pressed = ProgressRing.pressedAt(_press.value);
    final base = _pressFrom;
    if (base == null) return pressed;
    // Lift (matched through the press) and the rest all go on from where
    // the release left them, up to the full press.
    return (
      widen: math.max(base.widen, pressed.widen),
      light: math.max(base.light, pressed.light),
      lift: pressed.lift,
    );
  }

  /// A finger down: from where a release in progress left the ring.
  void _pressIn() {
    final current = _effects;
    _release.stop();
    _releasedFrom = null;
    _pressFrom = current.widen > 0 || current.light > 0 ? current : null;
    _press.value = _pressForLift(current.lift);
    _press.forward();
  }

  /// The press whose lift is [lift] ([ProgressRing.liftCurve] inverted by
  /// bisection), so a ring caught mid-release goes on rising instead of
  /// jumping.
  static double _pressForLift(double lift) {
    if (lift <= 0) return 0;
    if (lift >= 1) return 1;
    var low = 0.0;
    var high = 1.0;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      if (ProgressRing.liftCurve.transform(mid) < lift) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  /// The finger left (or the scrub ended without it).
  void _pressOut() {
    if (_releasedFrom != null) return;
    final from = _effects;
    _press.stop();
    _pressFrom = null;
    if (from.widen == 0 && from.light == 0 && from.lift == 0) return;
    _releasedFrom = from;
    _release.forward(from: 0);
  }

  void _onPress() {
    final effects = _effects;
    _widen.value = effects.widen;
    _light.value = effects.light;
    final lift = _reduceMotion ? 0.0 : effects.lift;
    _lift.value = lift;
    final shared = widget.lift;
    if (shared == null || shared.value == lift) return;
    // The lens is not below this ring in the tree: it must not be marked
    // dirty while this ring builds (a track change aborts a press from
    // didUpdateWidget). It is told after the frame then.
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      shared.value = lift;
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.lift == shared) shared.value = _lift.value;
    });
  }

  /// After the frame: the lens lives in another subtree, which must not be
  /// marked dirty while this one is being built or torn down.
  static void _resetLift(ValueNotifier<double>? lift) {
    if (lift == null || lift.value == 0) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        lift.value = 0;
      } on FlutterError {
        // Disposed with its page meanwhile.
      }
    });
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
    _pressIn();
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
    _pressOut();
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
    // The blurred light is left out with the glass turned off, like every
    // other soft effect on a slow phone.
    final softLight = GlassTheme.resolveQuality(context) != GlassQuality.off;

    return _SeekSemantics(
      progress: widget.progress,
      onIncrease: () => _seekBy(const Duration(seconds: 10)),
      onDecrease: () => _seekBy(const Duration(seconds: -10)),
      child: SizedBox.square(
        dimension: widget.diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The arc and the label grow with the lens; the touch band
            // below keeps its size (the scrub reads angles, which scaling
            // leaves alone).
            IgnorePointer(
              child: ValueListenableBuilder<double>(
                valueListenable: _lift,
                builder: (_, lift, child) => Transform.scale(
                  scale: 1 + GlassLens.liftScale * lift,
                  child: child,
                ),
                child: SizedBox.square(
                  dimension: widget.diameter,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      RepaintBoundary(
                        child: CustomPaint(
                          size: Size.square(widget.diameter),
                          painter: _RingPainter(
                            arc: _arc,
                            scrub: _scrub,
                            widen: _widen,
                            light: _light,
                            holeFraction: holeFraction,
                            softLight: softLight,
                            start: colors.progressStart,
                            end: colors.progressEnd,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom:
                            widget.diameter /
                                2 *
                                (1 - GlassLens.hairlineFraction) -
                            9,
                        child: ExcludeSemantics(
                          child: _RemainingLabel(
                            progress: widget.progress,
                            scrub: _scrub,
                          ),
                        ),
                      ),
                    ],
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
      label: context.l10n.playbackPosition,
      value: context.l10n.playbackPositionValue(
        at(progress.position),
        at(progress.duration),
      ),
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

  /// 0 the thin arc, 1 the whole band.
  final ValueListenable<double> widen;

  /// Strength of the diffuse light, 0 to 1.
  final ValueListenable<double> light;
  final double holeFraction;

  /// Draws the blurred pass of the light (off with the glass off).
  final bool softLight;
  final Color start;
  final Color end;

  _RingPainter({
    required this.arc,
    required this.scrub,
    required this.widen,
    required this.light,
    required this.holeFraction,
    required this.softLight,
    required this.start,
    required this.end,
  }) : super(repaint: Listenable.merge([arc, scrub, widen, light]));

  @override
  void paint(Canvas canvas, Size size) {
    if (arc.value < 0) return;

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final stroke = ProgressRing.strokeAt(
      widen.value,
      radius: radius,
      holeFraction: holeFraction,
    );
    // Without the blurred pass there is nothing to see through the band:
    // it stays a plain fill.
    final light = softLight ? this.light.value : 0.0;
    final ratio = scrub.value ?? arc.value;
    final sweep = math.max(ratio * _kMaxSweep, 0.001);
    final arcRect = Rect.fromCircle(center: center, radius: stroke.radius);
    // Dark by the label, bright at the head; the tail sinks lower while
    // the light is on, so the head stands out.
    final gradient = SweepGradient(
      endAngle: sweep,
      colors: [
        start.withValues(alpha: lerpDouble(0.35, 0.15, light)),
        start,
        ProgressRing.headColor(widen.value, start: start, end: end),
      ],
      stops: const [0, 0.7, 1],
      transform: const GradientRotation(_kStartAngle),
    ).createShader(arcRect);

    // Both passes below go through one layer while the band is wide, cut
    // at the end by the falloff across the glass. At rest: no layer.
    final outer = Rect.fromCircle(center: center, radius: radius);
    final falloff = widen.value > 0;
    if (falloff) canvas.saveLayer(outer, Paint());

    // Both ends cut square across the band (radially), the head under the
    // finger: the glass band, and the arc's sector of it.
    // Diffuse light: the same band blurred, as seen through frosted glass,
    // kept to the glass band and to the arc's sector of it so both ends
    // stay cut square (radially). The sharp band needs no clip: it fills
    // the band exactly and its butt caps are already radial.
    if (light > 0) {
      canvas
        ..save()
        ..clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addOval(outer)
            ..addOval(
              Rect.fromCircle(center: center, radius: radius * holeFraction),
            ),
        )
        ..clipPath(
          Path()
            ..moveTo(center.dx, center.dy)
            ..arcTo(outer.inflate(radius), _kStartAngle, sweep, false)
            ..close(),
        )
        ..drawArc(
          arcRect,
          _kStartAngle,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.width
            ..strokeCap = StrokeCap.butt
            ..shader = gradient
            ..color = Colors.white.withValues(alpha: light)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              math.max(0.1, radius * (1 - holeFraction) * 0.25),
            ),
        )
        ..restore();
    }

    // The band itself, see-through while lit so the glow shows through
    // it; a plain fill again as the light goes on release.
    canvas.drawArc(
      arcRect,
      _kStartAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width
        // Butt cap: a round tail cap would sit before the gradient start
        // and wrap to the bright end colour. The head dot rounds the
        // other end at rest.
        ..strokeCap = StrokeCap.butt
        ..shader = gradient
        // With a shader, only the alpha of the colour applies.
        ..color = Colors.white.withValues(alpha: 1 - 0.45 * light),
    );

    if (falloff) {
      canvas
        ..drawRect(
          outer,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ProgressRing.bandFalloff(
              widen.value,
              holeFraction: holeFraction,
            ).createShader(outer),
        )
        ..restore();
    }

    // Bright head with a soft halo, at rest only: pressed, the band's
    // square head sits under the finger.
    final dot = 1 - widen.value;
    if (dot <= 0) return;
    final headAngle = _kStartAngle + sweep;
    final head =
        center +
        Offset(math.cos(headAngle), math.sin(headAngle)) * stroke.radius;
    canvas
      ..drawCircle(
        head,
        6,
        Paint()
          ..color = start.withValues(alpha: 0.55 * dot)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(head, 2.5, Paint()..color = end.withValues(alpha: dot));
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.arc != arc ||
      oldDelegate.scrub != scrub ||
      oldDelegate.widen != widen ||
      oldDelegate.light != light ||
      oldDelegate.holeFraction != holeFraction ||
      oldDelegate.softLight != softLight ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}
