import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/primitives/color_primitives.dart';
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
}
