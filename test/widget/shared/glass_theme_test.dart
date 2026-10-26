import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/components/glass_theme.dart';

void main() {
  testWidgets('surfaces carrying text are thick and never boost colours', (
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

    for (final name in ['bar high', 'bar low', 'sheet high', 'sheet low']) {
      expect(configs[name]!.saturation, 1, reason: name);
      expect(configs[name]!.fill.a, greaterThanOrEqualTo(.65), reason: name);
    }
    // Decorative glass over the artwork keeps its colour.
    expect(configs['now playing']!.saturation, greaterThan(1));
  });
}
