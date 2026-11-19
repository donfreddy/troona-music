import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/layout/app_layout.dart';
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
                // The section's margin around its card (AppSpacing.md).
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
        final sizes = <double>{};
        for (final label in labels) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(paragraph.didExceedMaxLines, isFalse, reason: label);
          // Not shrunk: the label's box is as wide as the label.
          final fitted = tester.renderObject<RenderBox>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(FittedBox),
            ),
          );
          expect(
            fitted.size.width,
            greaterThanOrEqualTo(paragraph.size.width - 0.5),
            reason: '$label: not shrunk',
          );
          sizes.add(paragraph.textScaler.scale(13));
        }
        // One size for every label, the phone's up to the cap.
        expect(sizes, hasLength(1));
        expect(
          sizes.single,
          closeTo(13 * math.min(scale, AppLayout.maxTextScale), 0.01),
        );
      });
    }
  }
}
