import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/progress_ring.dart';
import 'package:troona/l10n/app_localizations.dart';

const double _diameter = 300;
const double _hole = 190;
const double _gap = 12 * math.pi / 180;
const double _start = math.pi / 2 + _gap;
const double _maxSweep = 2 * math.pi - 2 * _gap;

void main() {
  late ValueNotifier<PlaybackProgress> progress;
  late List<Duration> seeks;
  late int dismissDrags;
  late ValueNotifier<double> lift;

  setUp(() {
    progress = ValueNotifier(
      const PlaybackProgress(
        position: Duration(seconds: 20),
        buffered: Duration.zero,
        duration: Duration(seconds: 200),
      ),
    );
    seeks = [];
    dismissDrags = 0;
    lift = ValueNotifier(0);
  });

  Future<void> pumpRing(WidgetTester tester, {bool reduceMotion = false}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            // Mimics the full player's drag-to-dismiss wrapper.
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (_) => dismissDrags++,
              child: Center(
                child: ProgressRing(
                  diameter: _diameter,
                  holeDiameter: _hole,
                  progress: progress,
                  onSeek: seeks.add,
                  lift: lift,
                ),
              ),
            ),
          ),
        ),
      );

  /// Global position on the touch band at [angle] (Flutter convention).
  Offset onBand(WidgetTester tester, double angle) {
    final center = tester.getCenter(find.byType(ProgressRing));
    const radius = (_diameter + _hole) / 4;
    return center + Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  double expectedRatio(double angle) => (angle - _start) / _maxSweep;

  testWidgets('shows the remaining time', (tester) async {
    await pumpRing(tester);
    expect(find.text('3:00'), findsOneWidget);

    progress.value = progress.value.copyWith(
      position: const Duration(seconds: 50, milliseconds: 400),
    );
    await tester.pump();
    // 149.6 s left, rounded up.
    expect(find.text('2:30'), findsOneWidget);
  });

  testWidgets('scrubbing on the ring seeks once, on release', (tester) async {
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi * 0.9));
    await tester.pump();
    // Scrub up the left side to 9 o'clock.
    await gesture.moveTo(onBand(tester, math.pi * 0.95));
    await tester.pump();
    await gesture.moveTo(onBand(tester, math.pi));
    await tester.pump();
    expect(seeks, isEmpty);

    // The label follows the scrub position live.
    final scrubbed = Duration(
      milliseconds: (200000 * expectedRatio(math.pi)).round(),
    );
    final left = const Duration(seconds: 200) - scrubbed;
    final remaining = Duration(seconds: (left.inMilliseconds / 1000).ceil());
    final label =
        '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    expect(find.text(label), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(seeks, hasLength(1));
    expect(
      seeks.single.inMilliseconds,
      closeTo(200000 * expectedRatio(math.pi), 50),
    );
  });

  testWidgets('a vertical scrub does not trigger drag-to-dismiss', (
    tester,
  ) async {
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(dismissDrags, 0);
    expect(seeks, hasLength(1));
  });

  testWidgets('touches in the centre are left to the carousel', (tester) async {
    await pumpRing(tester);
    final center = tester.getCenter(find.byType(ProgressRing));
    await tester.dragFrom(center, const Offset(0, 80));
    await tester.pumpAndSettle();

    expect(seeks, isEmpty);
    expect(dismissDrags, 1);
  });

  testWidgets('crossing the label gap does not jump to the other end', (
    tester,
  ) async {
    await pumpRing(tester);
    // Start just after the gap (track start), then move back across it.
    final gesture = await tester.startGesture(onBand(tester, _start + 0.05));
    await tester.pump();
    await gesture.moveTo(onBand(tester, _start + 0.08));
    await tester.pump();
    await gesture.moveTo(onBand(tester, _start - 2 * _gap - 0.05));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(seeks.single.inSeconds, lessThan(5));
  });

  testWidgets('does nothing while the duration is unknown', (tester) async {
    progress.value = PlaybackProgress.zero;
    await pumpRing(tester);
    await tester.dragFrom(onBand(tester, math.pi), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(seeks, isEmpty);
    // The band still owns the gesture: no accidental dismiss.
    expect(dismissDrags, 0);
  });

  testWidgets('a plain tap on the ring does not seek, and the band settles '
      'back', (tester) async {
    await pumpRing(tester);
    await tester.tapAt(onBand(tester, math.pi));
    await tester.pumpAndSettle();
    expect(seeks, isEmpty);
    expect(lift.value, 0);
  });

  testWidgets('a finger on the band lifts the ring within 220 ms, and it '
      'settles within 240 ms of the release', (tester) async {
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi));
    await tester.pump();
    // No movement needed: the press itself answers.
    await tester.pump(const Duration(milliseconds: 110));
    expect(lift.value, allOf(greaterThan(0.5), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 110));
    expect(lift.value, 1);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(lift.value, 0);
  });

  testWidgets('nothing grows when the phone asks for less motion', (
    tester,
  ) async {
    await pumpRing(tester, reduceMotion: true);
    final gesture = await tester.startGesture(onBand(tester, math.pi));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(lift.value, 0);
    final scale = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(ProgressRing),
            matching: find.byType(Transform),
          ),
        )
        .map((t) => t.transform.getMaxScaleOnAxis());
    expect(scale, everyElement(1.0));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  RenderObject ringPaint(WidgetTester tester) => tester.renderObject(
    find
        .descendant(
          of: find.byType(ProgressRing),
          matching: find.byType(CustomPaint),
        )
        .first,
  );

  /// Width of the whole glass band of the test ring.
  const band = _diameter / 2 * (1 - _hole / _diameter);

  /// Paints an arc [width] wide; blurred (the light) or sharp (the band).
  PaintPattern arc(
    double width, {
    bool? blurred,
    double? alpha,
    double tolerance = 1e-6,
  }) => paints
    ..something((method, args) {
      if (method != #drawArc) return false;
      final paint = args[4] as Paint;
      return (paint.strokeWidth - width).abs() < tolerance &&
          (blurred == null || (paint.maskFilter != null) == blurred) &&
          (alpha == null || (paint.color.a - alpha).abs() < 1e-3);
    });

  /// Width of the sharp band as last painted.
  double sharpWidth(WidgetTester tester) {
    var width = -1.0;
    expect(
      ringPaint(tester),
      paints..something((method, args) {
        if (method != #drawArc) return false;
        final paint = args[4] as Paint;
        if (paint.maskFilter != null) return false;
        width = paint.strokeWidth;
        return true;
      }),
    );
    return width;
  }

  testWidgets('the arc widens into the lit band under the finger, then the '
      'light goes before the band narrows', (tester) async {
    await pumpRing(tester);
    expect(ringPaint(tester), arc(2.5));

    final gesture = await tester.startGesture(onBand(tester, math.pi));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(ringPaint(tester), arc(band, blurred: true));
    expect(ringPaint(tester), arc(band, blurred: false));

    await gesture.up();
    await tester.pump();
    // 40 % of the release: the light is out, the band still wide, the lens
    // well on its way back.
    await tester.pump(ProgressRing.releaseDuration * 0.4);
    expect(ringPaint(tester), isNot(arc(band, blurred: true)));
    expect(ringPaint(tester), arc(band));
    expect(lift.value, lessThan(0.3));

    await tester.pump(ProgressRing.releaseDuration * 0.6);
    expect(ringPaint(tester), arc(2.5));
    expect(lift.value, 0);
  });

  testWidgets('a ring rebuilt for another track mid-press settles back '
      'without seeking', (tester) async {
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi * 0.9));
    await gesture.moveTo(onBand(tester, math.pi));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(lift.value, 1);

    // A new clock, handed down by a rebuild: the press ends during build.
    progress = ValueNotifier(
      const PlaybackProgress(
        position: Duration.zero,
        buffered: Duration.zero,
        duration: Duration(seconds: 90),
      ),
    );
    await pumpRing(tester);
    expect(tester.takeException(), isNull);
    await tester.pump(ProgressRing.releaseDuration);
    await tester.pump();
    expect(lift.value, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(seeks, isEmpty);
  });

  testWidgets('released before the press is done, the ring still settles '
      'slowly into rest', (tester) async {
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final pressed = lift.value;
    expect(pressed, greaterThan(0.5));

    await gesture.up();
    await tester.pump();
    await tester.pump(ProgressRing.releaseDuration * 0.5);
    expect(lift.value, lessThan(pressed * 0.2), reason: 'starts back at once');
    await tester.pump(ProgressRing.releaseDuration * 0.4);
    expect(lift.value, lessThan(0.01), reason: 'and slows into rest');
    await tester.pump(ProgressRing.releaseDuration * 0.1);
    expect(lift.value, 0);
    expect(ringPaint(tester), arc(2.5));
  });

  testWidgets('a finger back on the ring mid-release lifts it from where '
      'it was', (tester) async {
    await pumpRing(tester);
    final first = await tester.startGesture(onBand(tester, math.pi));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await first.up();
    await tester.pump();
    await tester.pump(ProgressRing.releaseDuration * 0.3);
    final midway = lift.value;
    expect(midway, allOf(greaterThan(0.1), lessThan(0.9)));

    final wide = sharpWidth(tester);
    final again = await tester.startGesture(onBand(tester, math.pi));
    await tester.pump();
    expect(lift.value, closeTo(midway, 0.01), reason: 'no jump');
    expect(sharpWidth(tester), greaterThanOrEqualTo(wide - 1e-6));
    expect(ringPaint(tester), arc(band, blurred: true), reason: 'still lit');
    await tester.pump(const Duration(milliseconds: 16));
    expect(lift.value, greaterThan(midway), reason: 'rising again');
    await again.up();
    await tester.pumpAndSettle();
  });

  testWidgets('with the glass off the band widens without the blurred '
      'light', (tester) async {
    GlassTheme.overrideQuality(GlassQuality.off);
    addTearDown(() => GlassTheme.overrideQuality(null));
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi));
    await tester.pump();
    await tester.pump(ProgressRing.pressDuration);
    expect(ringPaint(tester), isNot(arc(band, blurred: true)));
    // Nothing to see through it: it stays a plain, full band.
    expect(ringPaint(tester), arc(band, alpha: 1));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  group('the band', () {
    const radius = _diameter / 2;
    const holeFraction = _hole / _diameter;
    ({double width, double radius}) at(double press) => ProgressRing.strokeAt(
      press,
      radius: radius,
      holeFraction: holeFraction,
    );

    test('is the thin arc on the hairline at rest', () {
      expect(at(0).width, 2.5);
      expect(at(0).radius, radius * 0.795);
    });

    test('fills the glass band exactly when pressed', () {
      final band = at(1);
      expect(
        band.radius - band.width / 2,
        closeTo(radius * holeFraction, 1e-9),
      );
      expect(band.radius + band.width / 2, closeTo(radius, 1e-9));
    });

    test('is dense against the cover and thins out to nothing before the '
        'rim, once wide only', () {
      final wide = ProgressRing.bandFalloff(1, holeFraction: holeFraction);
      final alphas = [for (final c in wide.colors) c.a];
      expect(wide.stops![1], holeFraction, reason: 'whole up to the cover');
      expect(alphas.take(2), everyElement(1.0));
      expect(alphas.last, 0);
      for (var i = 1; i < alphas.length; i++) {
        expect(alphas[i], lessThanOrEqualTo(alphas[i - 1]));
      }
      expect(wide.stops!.last, 1, reason: 'the gradient ends on the rim');

      // The thin arc at rest is whole, wherever it sits on the band.
      final rest = ProgressRing.bandFalloff(0, holeFraction: holeFraction);
      expect([for (final c in rest.colors) c.a], everyElement(1.0));
    });

    test('the head is white on the thin arc, a light blue on the band', () {
      const start = Color(0xFF8FB4FF);
      const end = Color(0xFFFFFFFF);
      expect(ProgressRing.headColor(0, start: start, end: end), end);
      final head = ProgressRing.headColor(1, start: start, end: end);
      expect(head, isNot(end));
      expect(head.computeLuminance(), greaterThan(start.computeLuminance()));
    });

    test('on release the light goes first, then the band narrows and '
        'everything slows into rest', () {
      final held = ProgressRing.pressedAt(1);
      expect(held, (widen: 1.0, light: 1.0, lift: 1.0));
      RingPress at(double r) => ProgressRing.releasedAt(r, held);
      // 40 % in: the light is out, the band still wide, the ring well on
      // its way back.
      expect(at(ProgressRing.lightOffShare).light, 0);
      expect(at(ProgressRing.lightOffShare).widen, 1);
      expect(at(ProgressRing.lightOffShare).lift, lessThan(0.3));
      // Slow at the end, not at full speed.
      final late = at(0.95);
      expect(late.widen, lessThan(0.01));
      expect(late.lift, lessThan(0.01));
      expect(at(1), (widen: 0.0, light: 0.0, lift: 0.0));
    });

    test('a quick release goes from where the press was, without waiting '
        'for a light that never came', () {
      final early = ProgressRing.pressedAt(0.4);
      expect(early.light, 0);
      final halfway = ProgressRing.releasedAt(0.5, early);
      expect(halfway.widen, lessThan(early.widen * 0.2));
      expect(halfway.lift, lessThan(early.lift * 0.2));
      expect(ProgressRing.releasedAt(0.95, early).lift, lessThan(0.01));
    });
  });

  testWidgets('a drag starting on the time label does not seek', (
    tester,
  ) async {
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi / 2));
    await gesture.moveTo(onBand(tester, math.pi / 2 + 0.02));
    await tester.pump();
    await gesture.moveTo(onBand(tester, math.pi / 2 - 0.02));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(seeks, isEmpty);
  });

  testWidgets('a track change mid-scrub aborts the seek', (tester) async {
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi * 0.9));
    await gesture.moveTo(onBand(tester, math.pi));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(lift.value, greaterThan(0), reason: 'pressed');

    progress.value = const PlaybackProgress(
      position: Duration.zero,
      buffered: Duration.zero,
      duration: Duration(seconds: 100),
    );
    await tester.pump();
    await gesture.moveTo(onBand(tester, math.pi * 1.1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    // The band settles back while the finger is still down.
    expect(lift.value, 0);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(seeks, isEmpty);
  });

  testWidgets('a pointer cancel does not commit the scrub', (tester) async {
    await pumpRing(tester);
    final gesture = await tester.startGesture(onBand(tester, math.pi * 0.9));
    await gesture.moveTo(onBand(tester, math.pi));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(seeks, isEmpty);
  });

  testWidgets('haptic ticks are throttled on long tracks', (tester) async {
    var ticks = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') ticks++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    progress.value = const PlaybackProgress(
      position: Duration.zero,
      buffered: Duration.zero,
      duration: Duration(hours: 1),
    );
    await pumpRing(tester);

    final gesture = await tester.startGesture(onBand(tester, math.pi * 0.7));
    for (var i = 1; i <= 60; i++) {
      await gesture.moveTo(onBand(tester, math.pi * (0.7 + i * 0.01)));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    // 60 moves cross dozens of seconds each, but ticks are time-throttled.
    expect(ticks, lessThan(15));
    expect(seeks, hasLength(1));
  });

  testWidgets('is exposed to screen readers as a slider', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpRing(tester);

    final node = tester.getSemantics(find.byType(ProgressRing));
    expect(
      node,
      isSemantics(
        isSlider: true,
        value: '0:20 of 3:20',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );

    node.owner!.performAction(node.id, SemanticsAction.increase);
    expect(seeks, [const Duration(seconds: 30)]);
    handle.dispose();
  });
}
