import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/components/glass_settings.dart';
import 'package:troona/core/theme/components/glass_theme.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/widgets/app_theme_builder.dart';
import 'package:troona/shared/widgets/glass_card.dart';

void main() {
  late SettingsCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cubit = SettingsCubit(
      SettingsRepositoryImpl(await SharedPreferences.getInstance()),
    );
    await cubit.load();
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, {required GlassQuality detected}) =>
      tester.pumpWidget(
        AppThemeBuilder(
          settings: cubit,
          detected: detected,
          builder: (context, theme) => MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Builder(
                // A surface that blurs unless the glass is off.
                builder: (context) => GlassCard(
                  config: GlassTheme.bar(context),
                  child: const SizedBox(width: 100, height: 60),
                ),
              ),
            ),
          ),
        ),
      );

  Finder blur() => find.descendant(
    of: find.byType(GlassCard),
    matching: find.byType(BackdropFilter),
  );

  GlassQuality drawn(WidgetTester tester) =>
      GlassTheme.resolveQuality(tester.element(find.byType(GlassCard)));

  testWidgets('changing the setting redraws the glass with nothing else '
      'happening', (tester) async {
    await pump(tester, detected: GlassQuality.high);
    expect(drawn(tester), GlassQuality.high);
    expect(blur(), findsOneWidget);

    await cubit.setGlassQuality(GlassQuality.off);
    await tester.pumpAndSettle();
    expect(drawn(tester), GlassQuality.off);
    expect(blur(), findsNothing);

    await cubit.setGlassQuality(GlassQuality.auto);
    await tester.pumpAndSettle();
    expect(drawn(tester), GlassQuality.high);
    expect(blur(), findsOneWidget);
  });

  testWidgets('auto draws with the tier detected on the device', (
    tester,
  ) async {
    await pump(tester, detected: GlassQuality.off);
    expect(drawn(tester), GlassQuality.off);

    await cubit.setGlassQuality(GlassQuality.high);
    await tester.pumpAndSettle();
    expect(drawn(tester), GlassQuality.high, reason: 'the setting wins');
  });

  test('a tier is never blended, and never auto in the theme', () {
    const high = GlassSettings(GlassQuality.high);
    const off = GlassSettings(GlassQuality.off);
    expect(high.lerp(off, 0.49).quality, GlassQuality.high);
    expect(high.lerp(off, 0.5).quality, GlassQuality.off);
    expect(
      GlassSettings.effective(GlassQuality.auto, GlassQuality.low),
      GlassQuality.low,
    );
    expect(() => GlassSettings(GlassQuality.auto), throwsAssertionError);
  });
}
