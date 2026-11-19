import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_filter.dart';
import 'package:troona/core/theme/components/glass_theme.dart';

void main() {
  testWidgets('surfaces carrying text temper their boost with a tint', (
    tester,
  ) async {
    final configs = <String, GlassConfig>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            for (final q in [GlassQuality.high, GlassQuality.low]) {
              configs['bar ${q.name}'] = GlassTheme.bar(context, quality: q);
              configs['sheet ${q.name}'] = GlassTheme.sheet(
                context,
                quality: q,
              );
            }
            configs['now playing'] = GlassTheme.nowPlaying(
              context,
              quality: GlassQuality.high,
            );
            return const SizedBox();
          },
        ),
      ),
    );

    final nowPlaying = configs['now playing']!.saturation;
    for (final name in ['bar high', 'sheet high']) {
      final glass = configs[name]!;
      // Milder than the decorative glass over the artwork, and never
      // alone: without a tint, small coloured shapes show as stains.
      expect(glass.saturation, inExclusiveRange(1, nowPlaying), reason: name);
      expect(glass.fill.a, greaterThan(.14), reason: name); // about 15 %
    }
    // Balanced: an opaque tint, nothing behind to boost.
    for (final name in ['bar low', 'sheet low']) {
      expect(configs[name]!.blurSigma, 0, reason: name);
    }
  });

  testWidgets('content cards have no edge, so their fill shows on its own '
      'on every tier', (tester) async {
    final content = <GlassQuality, GlassConfig>{};
    final cards = <GlassQuality, GlassConfig>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            for (final q in GlassQuality.values) {
              content[q] = GlassTheme.content(context, quality: q);
              cards[q] = GlassTheme.card(context, quality: q);
            }
            return const SizedBox();
          },
        ),
      ),
    );

    for (final q in GlassQuality.values) {
      final glass = content[q]!;
      expect(glass.borderWidth, 0, reason: q.name);
      expect(glass.blurSigma, 0, reason: 'scrolling content: ${q.name}');
      // At least as visible as the low tier's boosted card, the floor
      // a card without an edge reads at against the page.
      expect(glass.fill.a, greaterThanOrEqualTo(.075), reason: q.name);
    }
    // The high tier's card leans on its edge; its fill alone does not.
    expect(cards[GlassQuality.high]!.fill.a, lessThan(.05));
    expect(content[GlassQuality.low]!.fill, cards[GlassQuality.low]!.fill);
    expect(content[GlassQuality.off]!.fill, cards[GlassQuality.off]!.fill);
  });

  /// Relative luminance of an sRGB channel value in 0..1.
  double linear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  /// Contrast of white text over [glass] with a white cover under it: the
  /// cover through the glass's colour matrix, then its tint over it.
  double whiteOnWhiteCover(GlassConfig glass) {
    final through = _channel(
      GlassFilter.materialMatrix(glass.saturation, glass.exposure),
    );
    final a = glass.fill.a;
    double over(double tint) => tint * a + through * (1 - a);
    final l =
        0.2126 * linear(over(glass.fill.r)) +
        0.7152 * linear(over(glass.fill.g)) +
        0.0722 * linear(over(glass.fill.b));
    return 1.05 / (l + 0.05);
  }

  testWidgets('the header keeps white text readable over a white cover, on '
      'every tier that blurs; the tab bar lets colours through', (
    tester,
  ) async {
    final configs = <String, GlassConfig>{};
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            for (final q in GlassQuality.values) {
              configs['header ${q.name}'] = GlassTheme.header(
                context,
                quality: q,
              );
              configs['bar ${q.name}'] = GlassTheme.bar(context, quality: q);
            }
            return const SizedBox();
          },
        ),
      ),
    );

    for (final q in [GlassQuality.high, GlassQuality.low]) {
      final header = configs['header ${q.name}']!;
      expect(header.exposure, GlassTheme.headerExposure, reason: q.name);
      expect(
        whiteOnWhiteCover(header),
        greaterThanOrEqualTo(4.5),
        reason: 'header ${q.name}',
      );
      // The shell darkens content before it reaches the tab bar.
      expect(configs['bar ${q.name}']!.exposure, 1, reason: q.name);
    }
    // Without blur, the bar is opaque: nothing to expose.
    expect(configs['header off']!.blurSigma, 0);
    // Today's glass, for the record: white text washed out.
    expect(whiteOnWhiteCover(configs['bar high']!), lessThan(2));
  });
}

/// White (1.0) through the red row of [matrix], in 0..1.
double _channel(List<double> matrix) =>
    (matrix[0] + matrix[1] + matrix[2]) + matrix[4] / 255;
