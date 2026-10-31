import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/core/theme/semantic/app_icons.dart';
import 'package:troona/features/library/presentation/widgets/track_list_tile.dart';
import 'package:troona/features/player/data/playback_session_store.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_icon_button.dart';

import '../../helpers/fake_player.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('a small icon still takes a 44 dp touch target, labelled by '
      'its tooltip', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        AppIconButton(
          icon: AppIcons.close,
          tooltip: 'Close',
          size: 18,
          onPressed: () => taps++,
        ),
      ),
    );

    final button = find.byType(AppIconButton);
    expect(tester.getSize(button), const Size(44, 44));
    expect(
      tester.getSemantics(button),
      isSemantics(
        tooltip: 'Close',
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );

    // Near the corner, well outside the 18 dp icon.
    await tester.tapAt(tester.getTopLeft(button) + const Offset(3, 3));
    expect(taps, 1);
  });

  testWidgets('disabled: no tap action', (tester) async {
    await tester.pumpWidget(
      _app(
        const AppIconButton(
          icon: AppIcons.skipNext,
          tooltip: 'Next',
          onPressed: null,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(AppIconButton)),
      isSemantics(tooltip: 'Next', isButton: true, isEnabled: false),
    );
  });

  testWidgets('a song row has a labelled options button, 44 dp wide', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final port = FakeAudioPort();
    final bloc = buildTestPlayerBloc(
      port,
      PlaybackSessionStore(await SharedPreferences.getInstance()),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      // Not awaited: under the test's fake clock the close never settles.
      unawaited(bloc.close());
      unawaited(port.close());
    });

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: _app(
          TrackListTile(track: testTrack('1', durationMs: 60000), onTap: () {}),
        ),
      ),
    );

    final options = find.byTooltip('More options');
    expect(options, findsOneWidget);
    expect(tester.getSize(options), const Size(44, 44));
  });
}
