import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/equalizer/domain/entities/eq_layout.dart';
import 'package:troona/features/equalizer/presentation/widgets/eq_graph.dart';

import '../../helpers/fake_equalizer.dart';

const _size = Size(340, 220);

void main() {
  group('EqGraphGeometry', () {
    final g = EqGraphGeometry(fiveBands, _size);

    test('bands go across on a log scale, inside the plot', () {
      final xs = [for (var i = 0; i < 5; i++) g.xOf(i)];
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]));
      }
      expect(xs.first, greaterThan(g.plot.left));
      expect(xs.last, lessThan(g.plot.right));
    });

    test('heights map back to gains by half decibels, snapped to 0', () {
      expect(g.dbAt(g.yOf(6)), 6);
      expect(g.dbAt(g.yOf(-4.5)), -4.5);
      expect(g.dbAt(g.yOf(0.4)), 0);
      expect(g.dbAt(g.yOf(-0.5)), 0);
      expect(g.dbAt(g.plot.top - 100), fiveBands.maxDb);
      expect(g.dbAt(g.plot.bottom + 100), fiveBands.minDb);
    });

    test('the closest band to a point across', () {
      expect(g.nearestBand(0), 0);
      expect(g.nearestBand(g.xOf(2) + 3), 2);
      expect(g.nearestBand(_size.width), 4);
    });

    test('ticks every 6 dB on a wide range, 3 on a narrow one', () {
      expect(g.ticks, [-12, -6, 0, 6, 12]);
      expect(
        EqGraphGeometry(layoutOf([100, 1000], min: -6, max: 6), _size).ticks,
        [-6, -3, 0, 3, 6],
      );
    });

    test('ten bands on a narrow screen write every other frequency', () {
      expect(EqGraphGeometry(tenBands, const Size(320, 200)).halfLabels, true);
      expect(g.halfLabels, isFalse);
    });
  });

  group('EqGraph', () {
    late List<List<double>> drawn;
    late List<List<double>> committed;
    late List<(int, double)> bands;
    late int cancels;

    /// The graph; [fresh] false keeps what was recorded, for a rebuild.
    Future<void> pump(
      WidgetTester tester, {
      EqLayout? layout,
      List<double>? gains,
      bool enabled = true,
      bool fresh = true,
    }) async {
      if (fresh) {
        drawn = [];
        committed = [];
        bands = [];
        cancels = 0;
      }
      final l = layout ?? fiveBands;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox.fromSize(
                size: _size,
                child: EqGraph(
                  layout: l,
                  gains: gains ?? List.filled(l.bands.length, 0),
                  enabled: enabled,
                  onDraw: drawn.add,
                  onCommit: committed.add,
                  onCancel: () => cancels++,
                  onBand: (band, db) => bands.add((band, db)),
                  bandLabel: (hz) => '${hz.round()} hertz',
                  bandValue: (db) => '$db decibels',
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// Where [band] at [db] sits on screen.
    Offset at(WidgetTester tester, int band, double db, [EqLayout? layout]) {
      final origin = tester.getTopLeft(find.byType(EqGraph));
      final g = EqGraphGeometry(layout ?? fiveBands, _size);
      return origin + Offset(g.xOf(band), g.yOf(db));
    }

    testWidgets('a touch sets the closest band to the finger\'s height', (
      tester,
    ) async {
      await pump(tester);
      await tester.tapAt(at(tester, 1, 6) + const Offset(4, 0));
      expect(drawn.first, [0, 6, 0, 0, 0]);
      expect(committed.single, [0, 6, 0, 0, 0]);
    });

    testWidgets('a slide across sets every band it crosses', (tester) async {
      await pump(tester);
      final gesture = await tester.startGesture(at(tester, 0, 3));
      // One move, fast: the middle bands are crossed within a frame.
      await gesture.moveTo(at(tester, 4, 3));
      await gesture.up();
      expect(committed.single, [3, 3, 3, 3, 3]);
      expect(drawn.length, greaterThanOrEqualTo(2));
    });

    testWidgets('a double tap sets a band back to 0', (tester) async {
      await pump(tester, gains: [0, 0, 6, 0, 0]);
      await tester.tapAt(at(tester, 2, 6));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(at(tester, 2, 6));
      expect(committed.last, [0, 0, 0, 0, 0]);
    });

    testWidgets('two taps far apart in time are two touches', (tester) async {
      await pump(tester);
      await tester.tapAt(at(tester, 2, 6));
      await tester.pump(EqGraph.doubleTapWindow * 2);
      await tester.tapAt(at(tester, 2, 6));
      expect(committed.last, [0, 0, 6, 0, 0]);
    });

    testWidgets('a touch taken away drops what was drawn', (tester) async {
      await pump(tester);
      final gesture = await tester.startGesture(at(tester, 1, 6));
      await gesture.moveTo(at(tester, 3, 6));
      await gesture.cancel();
      await tester.pump();
      expect(drawn, isNotEmpty);
      expect(committed, isEmpty);
      expect(cancels, 1);
    });

    testWidgets('switched off under the finger: what was drawn is kept', (
      tester,
    ) async {
      await pump(tester);
      final gesture = await tester.startGesture(at(tester, 1, 6));
      await gesture.moveTo(at(tester, 2, 6));
      await pump(tester, enabled: false, fresh: false);
      await tester.pump();
      expect(committed.single, [0, 6, 6, 0, 0]);
      await gesture.up();
      expect(committed, hasLength(1));
      expect(cancels, 0);
    });

    testWidgets('closed under the finger: what was drawn is kept', (
      tester,
    ) async {
      await pump(tester);
      final gesture = await tester.startGesture(at(tester, 1, 6));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(committed.single, [0, 6, 0, 0, 0]);
      await gesture.up();
    });

    testWidgets('off, it takes no touch', (tester) async {
      await pump(tester, enabled: false);
      await tester.tapAt(at(tester, 1, 6));
      expect(drawn, isEmpty);
      expect(committed, isEmpty);
    });

    testWidgets('a vertical drag on it never closes the sheet it is in', (
      tester,
    ) async {
      drawn = [];
      committed = [];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => SizedBox.fromSize(
                    size: _size,
                    child: EqGraph(
                      layout: fiveBands,
                      gains: const [0, 0, 0, 0, 0],
                      enabled: true,
                      onDraw: drawn.add,
                      onCommit: committed.add,
                      onCancel: () {},
                      onBand: (_, _) {},
                      bandLabel: (_) => '',
                      bandValue: (_) => '',
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final graph = find.byType(EqGraph);
      final top = tester.getTopLeft(graph);
      final g = EqGraphGeometry(fiveBands, _size);
      await tester.dragFrom(
        top + Offset(g.xOf(2), g.yOf(12)),
        const Offset(0, 400),
      );
      await tester.pumpAndSettle();
      expect(graph, findsOneWidget);
      expect(committed.single[2], fiveBands.minDb);
    });

    testWidgets('each band is a slider for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, gains: [0, 2, 0, 0, 0]);
      final node = tester.getSemantics(find.byType(EqGraph));
      final children = <SemanticsNode>[];
      void collect(SemanticsNode n) {
        if (n.label.endsWith('hertz')) children.add(n);
        n.visitChildren((c) {
          collect(c);
          return true;
        });
      }

      collect(node);
      expect(children, hasLength(5));
      final band = children[1];
      expect(band.label, '230 hertz');
      expect(band.value, '2.0 decibels');
      expect(band.increasedValue, '3.0 decibels');
      expect(band.getSemanticsData().hasAction(SemanticsAction.increase), true);

      band.owner!.performAction(band.id, SemanticsAction.decrease);
      expect(bands.single, (1, 1.0));
      handle.dispose();
    });
  });
}
