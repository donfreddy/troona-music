import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';
import 'package:troona/features/player/presentation/bloc/palette/track_palette_cubit.dart';
import 'package:troona/shared/widgets/ambient_background.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
}

/// A secondary label (60 % of the dark label colour) painted on [background].
Color _secondaryOn(Color background) =>
    Color.alphaBlend(ColorPrimitives.labelSecondaryDark, background);

void main() {
  // Palette backgrounds as TrackPaletteCubit makes them: HSL lightness .25.
  final hues = {
    'blue': 230.0,
    'violet': 270.0,
    'red': 0.0,
    'green': 120.0,
    'yellow': 58.0,
    'cyan': 185.0,
  };
  Color cover(double hue) => HSLColor.fromAHSL(1, hue, .9, .25).toColor();

  group('fitForText', () {
    for (final MapEntry(key: name, value: hue) in hues.entries) {
      test('$name: secondary text keeps 4.5:1 over the glow', () {
        final peak = DynamicBackground.peakOf(
          DynamicBackground.fitForText(cover(hue)),
        );
        expect(_contrast(_secondaryOn(peak), peak), greaterThanOrEqualTo(4.5));
      });
    }

    test('the default ambient glow is readable too', () {
      for (final color in [
        ColorPrimitives.ambientTop,
        ColorPrimitives.ambientEdge,
      ]) {
        final peak = DynamicBackground.peakOf(
          DynamicBackground.fitForText(color),
        );
        expect(_contrast(_secondaryOn(peak), peak), greaterThanOrEqualTo(4.5));
      }
    });

    test('without the cap, bright hues fail', () {
      final peak = DynamicBackground.peakOf(cover(hues['yellow']!));
      expect(_contrast(_secondaryOn(peak), peak), lessThan(4.5));
    });

    test('a dark colour comes back unchanged, a bright one keeps its hue', () {
      final deepBlue = HSLColor.fromAHSL(1, 230, .9, .15).toColor();
      expect(DynamicBackground.fitForText(deepBlue), deepBlue);

      final yellow = DynamicBackground.fitForText(cover(hues['yellow']!));
      expect(HSLColor.fromColor(yellow).hue, closeTo(58, 2));
      expect(HSLColor.fromColor(yellow).lightness, lessThan(.25));
    });
  });

  for (final (tone, glass, settles, stillMoving) in [
    (
      DynamicBackgroundTone.ambient,
      GlassQuality.high,
      const Duration(milliseconds: 2100),
      const Duration(seconds: 1),
    ),
    // Below the high tier, every glow follows quickly.
    (
      DynamicBackgroundTone.ambient,
      GlassQuality.low,
      const Duration(milliseconds: 400),
      null,
    ),
    (
      DynamicBackgroundTone.immersive,
      GlassQuality.high,
      const Duration(milliseconds: 400),
      null,
    ),
  ]) {
    testWidgets('${tone.name} on ${glass.name} glass: a new song\'s colours '
        'take ${DynamicBackground.transitionOf(tone, glass).inMilliseconds} '
        'ms', (tester) async {
      Widget glow(Color a) => MaterialApp(
        theme: AppTheme.withGlass(glass),
        home: DynamicBackground(
          colorA: a,
          colorB: a,
          tone: tone,
          child: const SizedBox.expand(),
        ),
      );
      await tester.pumpWidget(glow(const Color(0xFF203080)));
      await tester.pumpWidget(glow(const Color(0xFF802030)));
      if (stillMoving != null) {
        await tester.pump(stillMoving);
        expect(tester.hasRunningAnimations, isTrue);
      }
      await tester.pump(settles);
      expect(tester.hasRunningAnimations, isFalse);
    });
  }

  group('glow off', () {
    Widget page({required bool glow}) => MaterialApp(
      theme: AppTheme.withGlass(GlassQuality.high),
      home: DynamicBackground(
        colorA: const Color(0xFF203080),
        colorB: const Color(0xFF802030),
        tone: DynamicBackgroundTone.ambient,
        glow: glow,
        child: const _Counter(),
      ),
    );

    double glowOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(DynamicBackground),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;

    testWidgets('fades the glow to black over the glow\'s own transition, '
        'and back', (tester) async {
      final duration = DynamicBackground.transitionOf(
        DynamicBackgroundTone.ambient,
        GlassQuality.high,
      );
      await tester.pumpWidget(page(glow: true));
      expect(glowOpacity(tester), 1);

      await tester.pumpWidget(page(glow: false));
      await tester.pump(duration ~/ 2);
      expect(glowOpacity(tester), inExclusiveRange(0, 1), reason: 'fading');
      await tester.pump(duration);
      expect(glowOpacity(tester), 0);

      await tester.pumpWidget(page(glow: true));
      await tester.pumpAndSettle();
      expect(glowOpacity(tester), 1);
    });

    testWidgets('the page over it keeps its state', (tester) async {
      // No key: a global key would carry the state across a new parent and
      // hide a remount.
      await tester.pumpWidget(page(glow: true));
      final before = tester.state(find.byType(_Counter));

      await tester.pumpWidget(page(glow: false));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(_Counter)), same(before));
    });

    testWidgets('the app\'s background reads the switch from the theme', (
      tester,
    ) async {
      final palette = TrackPaletteCubit();
      addTearDown(palette.close);
      Widget app({required bool ambientGlow}) => BlocProvider.value(
        value: palette,
        child: MaterialApp(
          theme: AppTheme.withGlass(
            GlassQuality.high,
            ambientGlow: ambientGlow,
          ),
          home: const AmbientBackground(),
        ),
      );
      await tester.pumpWidget(app(ambientGlow: true));
      expect(glowOpacity(tester), 1);

      await tester.pumpWidget(app(ambientGlow: false));
      await tester.pumpAndSettle();
      expect(glowOpacity(tester), 0);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
