import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/player/presentation/bloc/player/player_bloc.dart';
import 'package:troona/features/player/presentation/widgets/progress_ring.dart';

const double _diameter = 300;
const double _hole = 190;
const double _gap = 12 * math.pi / 180;
const double _start = math.pi / 2 + _gap;
const double _maxSweep = 2 * math.pi - 2 * _gap;

void main() {
  late ValueNotifier<PlaybackProgress> progress;
  late List<Duration> seeks;
  late int dismissDrags;

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
  });

  Future<void> pumpRing(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
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

  testWidgets('a plain tap on the ring does not seek', (tester) async {
    await pumpRing(tester);
    await tester.tapAt(onBand(tester, math.pi));
    await tester.pumpAndSettle();
    expect(seeks, isEmpty);
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

    progress.value = const PlaybackProgress(
      position: Duration.zero,
      buffered: Duration.zero,
      duration: Duration(seconds: 100),
    );
    await tester.pump();
    await gesture.moveTo(onBand(tester, math.pi * 1.1));
    await tester.pump();
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
