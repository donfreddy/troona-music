import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/player/presentation/widgets/play_shuffle_buttons.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_button.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';

void main() {
  setUpAll(loadRoboto);

  for (final locale in const [Locale('en'), Locale('fr')]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('${locale.languageCode}, text x$scale: both fit the 48 dp '
          'of the detail pages\' action bar on a 360 dp phone', (tester) async {
        tester.view
          ..devicePixelRatio = 2
          ..physicalSize = const Size(360, 640) * 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark.copyWith(
              textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Roboto'),
            ),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // No height imposed: the buttons' own height is measured.
                  child: UnconstrainedBox(
                    constrainedAxis: Axis.horizontal,
                    child: PlayShuffleButtons(
                      tracks: [
                        testTrack('a', durationMs: 1000),
                        testTrack('b', durationMs: 1000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        for (final button in tester.widgetList<AppButton>(
          find.byType(AppButton),
        )) {
          final size = tester.getSize(find.byWidget(button));
          expect(size.height, lessThanOrEqualTo(48), reason: button.label);
        }
      });
    }
  }
}
