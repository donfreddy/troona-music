import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/palette_ink.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';
import 'package:troona/shared/widgets/palette_ink_scope.dart';

const _red = Color(0xFF7A1020);
const _blue = Color(0xFF102A7A);
const _edge = Color(0xFF301040);

PaletteInk _inkOf(Color a, Color b) => PaletteInk.of(
  DynamicBackground.fitForText(a),
  DynamicBackground.fitForText(b),
);

void main() {
  late PaletteInk? seen;
  late ValueNotifier<Color> top;

  Future<void> pump(WidgetTester tester) async {
    seen = null;
    top = ValueNotifier(_red);
    addTearDown(top.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ValueListenableBuilder<Color>(
          valueListenable: top,
          builder: (_, color, _) => PaletteInkScope(
            colorA: color,
            colorB: _edge,
            tone: DynamicBackgroundTone.immersive,
            child: Builder(
              builder: (context) {
                seen = PaletteInkScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the ink of the glow, at once', (tester) async {
    await pump(tester);
    expect(seen, _inkOf(_red, _edge));
  });

  testWidgets('a new song: the ink moves with the background, on its '
      'curve and in its time', (tester) async {
    await pump(tester);
    top.value = _blue;
    await tester.pump();
    final duration = DynamicBackground.transitionOf(
      DynamicBackgroundTone.immersive,
    );
    await tester.pump(duration ~/ 2);
    final t = Curves.easeInOutCubic.transform(0.5);
    expect(
      seen,
      PaletteInk.of(
        Color.lerp(
          DynamicBackground.fitForText(_red),
          DynamicBackground.fitForText(_blue),
          t,
        )!,
        DynamicBackground.fitForText(_edge),
      ),
    );
    await tester.pump(duration);
    expect(seen, _inkOf(_blue, _edge));
  });

  testWidgets('a rebuild with the same colours starts no transition', (
    tester,
  ) async {
    final tick = ValueNotifier(0);
    addTearDown(tick.dispose);
    PaletteInk? ink;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (_, _, _) => PaletteInkScope(
            colorA: _red,
            colorB: _edge,
            tone: DynamicBackgroundTone.immersive,
            child: Builder(
              builder: (context) {
                ink = PaletteInkScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    tick.value++;
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(ink, _inkOf(_red, _edge));
  });

  /// The first stop of the background's radial glows, opaque again: the
  /// colours it paints this frame, (A, B).
  (Color, Color) painted(WidgetTester tester) {
    final glows = [
      for (final box in tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(DynamicBackground),
          matching: find.byType(DecoratedBox),
        ),
      ))
        if ((box.decoration as BoxDecoration).gradient
            case final RadialGradient g)
          g.colors[1].withValues(alpha: 1),
    ];
    return (glows[0], glows[1]);
  }

  testWidgets('frame by frame, the ink is the ink of what the background '
      'paints', (tester) async {
    final glow = ValueNotifier(_red);
    addTearDown(glow.dispose);
    PaletteInk? ink;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ValueListenableBuilder<Color>(
          valueListenable: glow,
          builder: (_, color, _) => Stack(
            children: [
              DynamicBackground(
                colorA: color,
                colorB: _edge,
                tone: DynamicBackgroundTone.immersive,
                child: const SizedBox.expand(),
              ),
              PaletteInkScope(
                colorA: color,
                colorB: _edge,
                tone: DynamicBackgroundTone.immersive,
                child: Builder(
                  builder: (context) {
                    ink = PaletteInkScope.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    glow.value = _blue;
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 45));
      final (a, b) = painted(tester);
      expect(ink, PaletteInk.of(a, b), reason: 'frame $i');
    }
  });

  testWidgets('no stop of the background paints brighter than the peak '
      'the ink is measured against', (tester) async {
    for (final tone in DynamicBackgroundTone.values) {
      for (final color in [_red, _blue, const Color(0xFFFFEB3B)]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: DynamicBackground(
              colorA: color,
              colorB: color,
              tone: tone,
              child: const SizedBox.expand(),
            ),
          ),
        );
        final peak = PaletteInk.glowPeakOf(
          DynamicBackground.fitForText(color),
        ).computeLuminance();
        for (final box in tester.widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(DynamicBackground),
            matching: find.byType(DecoratedBox),
          ),
        )) {
          if ((box.decoration as BoxDecoration).gradient
              case final RadialGradient g) {
            for (final stop in g.colors) {
              expect(
                Color.alphaBlend(
                  stop,
                  const Color(0xFF000000),
                ).computeLuminance(),
                lessThanOrEqualTo(peak + 1e-9),
                reason: '$tone $color',
              );
            }
          }
        }
      }
    }
  });

  testWidgets('outside a scope: the ink of the ambient glow', (tester) async {
    PaletteInk? outside;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          outside = PaletteInkScope.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(outside, PaletteInkScope.fallback);
  });
}
