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
  late int builds;
  late ValueNotifier<Color> top;

  Future<void> pump(WidgetTester tester) async {
    seen = null;
    builds = 0;
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
                builds++;
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

  testWidgets('the text below rebuilds only while the glow moves', (
    tester,
  ) async {
    await pump(tester);
    final before = builds;
    top.value = _red;
    await tester.pump(const Duration(seconds: 1));
    expect(builds, before);
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
