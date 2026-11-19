import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/semantic/app_colors.dart';

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
}
