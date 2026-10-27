import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
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
    for (final name in ['bar low', 'sheet low']) {
      expect(configs[name]!.saturation, 1, reason: name);
    }
  });
}
