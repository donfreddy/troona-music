import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/semantic/palette_ink.dart';
import 'package:troona/shared/widgets/dynamic_background.dart';

/// [ink] drawn on [ground], against [ground].
double _contrastOn(Color ink, Color ground) =>
    PaletteInk.contrastOf(Color.alphaBlend(ink, ground), ground);

/// Every ground a line can sit on: each glow at its brightest, black, and
/// the way between them.
List<Color> _grounds(Color a, Color b) {
  final peaks = [PaletteInk.glowPeakOf(a), PaletteInk.glowPeakOf(b)];
  return [
    for (final peak in peaks)
      for (var t = 0.0; t <= 1; t += 0.25)
        Color.lerp(peak, const Color(0xFF000000), t)!,
    for (var t = 0.0; t <= 1; t += 0.25) Color.lerp(peaks[0], peaks[1], t)!,
  ];
}

/// A glow as `CoverPalette` makes it (lightness .25 on top, .15 below),
/// then as the background paints it.
(Color, Color) _glow(double hue, double saturation) => (
  DynamicBackground.fitForText(
    HSLColor.fromAHSL(1, hue, saturation, .25).toColor(),
  ),
  DynamicBackground.fitForText(
    HSLColor.fromAHSL(1, (hue + 40) % 360, saturation, .15).toColor(),
  ),
);

void main() {
  group('floors', () {
    for (var hue = 0.0; hue < 360; hue += 15) {
      for (final saturation in [0.05, 0.4, 0.9]) {
        test('hue $hue, saturation $saturation: every level keeps its floor '
            'on every ground', () {
          final (a, b) = _glow(hue, saturation);
          final ink = PaletteInk.of(a, b);
          for (final ground in _grounds(a, b)) {
            expect(_contrastOn(ink.far, ground), greaterThanOrEqualTo(2));
            expect(_contrastOn(ink.near, ground), greaterThanOrEqualTo(3));
            expect(
              _contrastOn(ink.secondary, ground),
              greaterThanOrEqualTo(4.5),
            );
            expect(_contrastOn(ink.body, ground), greaterThanOrEqualTo(4.5));
            expect(_contrastOn(ink.primary, ground), greaterThanOrEqualTo(7));
          }
        });
      }
    }

    test('a bright cover, once fitted, still holds: yellow is the '
        'brightest hue', () {
      final (a, b) = (
        DynamicBackground.fitForText(const Color(0xFFFFEB3B)),
        DynamicBackground.fitForText(const Color(0xFFFFFFFF)),
      );
      final ink = PaletteInk.of(a, b);
      for (final ground in _grounds(a, b)) {
        expect(_contrastOn(ink.near, ground), greaterThanOrEqualTo(3));
      }
    });
  });

  group('as faint as each may be', () {
    test('one step less alpha falls below the floor on one of the '
        'grounds: a glow at its brightest, or black for the faintest', () {
      final (a, b) = _glow(0, 0.9);
      final ink = PaletteInk.of(a, b);
      final grounds = [
        PaletteInk.glowPeakOf(a),
        PaletteInk.glowPeakOf(b),
        const Color(0xFF000000),
      ];
      for (final (level, floor) in [
        (ink.far, 2.0),
        (ink.near, 3.0),
        (ink.secondary, 4.5),
      ]) {
        final fainter = level.withValues(alpha: level.a - 1 / 255);
        expect(
          grounds.any((g) => _contrastOn(fainter, g) < floor),
          isTrue,
          reason: 'floor $floor',
        );
      }
    });

    test('levels step down: secondary, near, far', () {
      final (a, b) = _glow(230, 0.9);
      final ink = PaletteInk.of(a, b);
      expect(ink.secondary.a, greaterThan(ink.near.a));
      expect(ink.near.a, greaterThan(ink.far.a));
    });

    test('alpha 1 when even opaque the ink cannot reach the floor', () {
      expect(
        PaletteInk.alphaFor(
          const Color(0xFF808080),
          const Color(0xFF707070),
          4.5,
        ),
        1,
      );
    });
  });

  group('tint', () {
    test('takes the hue of the main glow', () {
      final red = PaletteInk.of(_glow(0, 0.9).$1, _glow(0, 0.9).$2).body;
      expect(red.r, greaterThan(red.g));
      expect(red.r, greaterThan(red.b));
      final blue = PaletteInk.of(_glow(230, 0.9).$1, _glow(230, 0.9).$2).body;
      expect(blue.b, greaterThan(blue.r));
      expect(blue.b, greaterThan(blue.g));
    });

    test('a grey glow gives a neutral ink, never a hue it does not '
        'have', () {
      final ink = PaletteInk.of(_glow(0, 0.05).$1, _glow(0, 0.05).$2);
      expect(ink.body.r, closeTo(ink.body.g, 1e-6));
      expect(ink.body.g, closeTo(ink.body.b, 1e-6));
    });

    test('the line sung stays white', () {
      expect(
        PaletteInk.of(_glow(120, 0.9).$1, _glow(120, 0.9).$2).primary,
        const Color(0xFFFFFFFF),
      );
    });
  });

  test('the background bounds its glow with the same peak', () {
    const color = Color(0xFF552233);
    expect(DynamicBackground.peakOf(color), PaletteInk.glowPeakOf(color));
  });
}
