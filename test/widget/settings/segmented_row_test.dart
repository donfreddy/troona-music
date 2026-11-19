import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/widgets/segmented_row.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/roboto.dart';

void main() {
  setUpAll(loadRoboto);

  for (final locale in const [Locale('en'), Locale('fr')]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('glass setting, ${locale.languageCode}, 360 dp, text '
          'x$scale: every label on one line, whole', (tester) async {
        tester.view
          ..devicePixelRatio = 3
          ..physicalSize = const Size(360, 640) * 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        late List<String> labels;
        await tester.pumpWidget(
          MaterialApp(
            theme: robotoTheme(AppTheme.dark),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                // The section's margin around its card.
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    labels = [
                      l10n.settingsGlassAuto,
                      l10n.settingsGlassFull,
                      l10n.settingsGlassBalanced,
                      l10n.settingsGlassOff,
                    ];
                    return SegmentedRow<GlassQuality>(
                      icon: AppIcons.glassEffect,
                      iconColor: const Color(0xFF06B6D4),
                      label: l10n.settingsGlass,
                      values: GlassQuality.values,
                      labels: labels,
                      selected: GlassQuality.low,
                      onChanged: (_) {},
                    );
                  },
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        for (final label in labels) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          // Never cut: the whole label fits the box it is drawn in.
          expect(
            paragraph.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.5),
            reason: label,
          );
          final lineHeight = paragraph.getMinIntrinsicHeight(double.infinity);
          expect(
            paragraph.size.height,
            closeTo(lineHeight, 0.5),
            reason: '$label: one line',
          );
        }
      });
    }
  }
}
