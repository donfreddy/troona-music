import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';
import 'package:troona/features/history/domain/services/play_intensity.dart';
import 'package:troona/features/history/presentation/widgets/heat_cell.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

/// WCAG contrast of [label] drawn over the opaque [page].
double _contrast(Color label, Color page) {
  final shown = Color.alphaBlend(label, page).computeLuminance();
  final under = page.computeLuminance();
  final (light, dark) = shown > under ? (shown, under) : (under, shown);
  return (light + .05) / (dark + .05);
}

void main() {
  const colors = AppColors.dark;

  // Every label level below is used for text, down to 11 px: 4.5:1 on the
  // page, the WCAG floor for small text.
  for (final (name, label) in [
    ('primary', colors.labelPrimary),
    ('secondary', colors.labelSecondary),
    ('tertiary', colors.labelTertiary),
  ]) {
    test('$name text reads at 4.5:1 on the page', () {
      expect(_contrast(label, colors.bgPrimary), greaterThanOrEqualTo(4.5));
    });
  }

  test('tertiary stays below secondary: the levels still read apart', () {
    expect(colors.labelTertiary.a, lessThan(colors.labelSecondary.a));
  });

  // Accents fill buttons and switches and colour text and icons: each reads
  // at 4.5:1 on the page and on raised surfaces, and the text drawn on it
  // (its foreground) reads at 4.5:1 on it.
  for (final accent in AppAccent.values) {
    test('the ${accent.name} accent reads on the page and carries its text',
        () {
      final (color, foreground) = AppColors.accentOf(accent);
      expect(_contrast(color, colors.bgPrimary), greaterThanOrEqualTo(4.5));
      expect(_contrast(color, colors.bgElevated), greaterThanOrEqualTo(4.5));
      expect(_contrast(foreground, color), greaterThanOrEqualTo(4.5));
    });
  }

  test('lilac is the accent the app always had', () {
    final themed = AppColors.withAccent(AppAccent.lilac);
    expect(themed.accent, colors.accent);
    expect(themed.accentForeground, colors.accentForeground);
  });

  test('every accent is its own colour', () {
    final all = {for (final a in AppAccent.values) AppColors.accentOf(a).$1};
    expect(all, hasLength(AppAccent.values.length));
  });

  // The recap calendar writes the day's number on cells filled with the
  // accent at growing strength.
  for (final accent in AppAccent.values) {
    test('the ${accent.name} calendar: every day\'s number reads at 4.5:1',
        () {
      final themed = AppColors.withAccent(accent);
      for (var level = 0; level <= PlayIntensity.maxLevel; level++) {
        final cell = Color.alphaBlend(
          HeatCell.fillWith(themed, level),
          themed.bgPrimary,
        );
        expect(
          _contrast(HeatCell.inkOf(themed, level), cell),
          greaterThanOrEqualTo(4.5),
          reason: 'level $level',
        );
      }
    });
  }
}
