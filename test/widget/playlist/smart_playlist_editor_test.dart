import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/playlist/presentation/bloc/smart_editor/smart_editor_cubit.dart';
import 'package:troona/features/playlist/presentation/pages/smart_playlist_editor_page.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/fake_smart.dart';
import '../../helpers/roboto.dart';

void main() {
  setUpAll(loadRoboto);

  late MemoryPlaylists playlists;

  Future<SmartEditorCubit> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Playlist? playlist,
  }) async {
    playlists = MemoryPlaylists();
    final cubit = SmartEditorCubit(
      repo: playlists,
      source: fakeSmartSource(
        library: FakeSmartLibrary([
          testTrack('a', durationMs: 120000),
          testTrack('b', durationMs: 700000),
        ]),
        history: FakeSmartHistory(),
        playlists: playlists,
      ),
      playlist: playlist,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: robotoTheme(AppTheme.dark),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const SmartPlaylistEditorPage(),
        ),
      ),
    );
    await cubit.load();
    await tester.pumpAndSettle();
    addTearDown(cubit.close);
    return cubit;
  }

  for (final locale in const [Locale('en'), Locale('fr')]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('${locale.languageCode}, 360 x 640, text x$scale: '
          'nothing overflows, down to the footnote', (tester) async {
        tester.view
          ..devicePixelRatio = 3
          ..physicalSize = const Size(360, 640) * 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final cubit = await pump(tester, locale: locale);
        cubit
          ..addRule(const PlaysInPeriod(days: 365, count: 20))
          ..addRule(const LastPlayed(LastPlayedKind.olderThan, days: 365))
          ..addRule(
            const TextMatches(
              SmartTextField.artist,
              'A very long artist name, with more after it',
              contains: false,
            ),
          )
          ..addRule(
            const DurationBetween(
              min: Duration(minutes: 3),
              max: Duration(minutes: 6),
            ),
          )
          ..setRules(
            cubit.state.rules.copyWith(
              sort: SmartSort.lastPlayedOldest,
              limit: () => 250,
            ),
          );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.dragUntilVisible(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(SmartPlaylistEditorPage)),
            ).smartFootnote,
          ),
          find.byType(ListView).first,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a template fills the name and counts its songs', (tester) async {
    final cubit = await pump(tester);
    // No name yet: nothing to save.
    expect(cubit.state.canSave, isFalse);

    await tester.tap(find.text('Lossless'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Lossless',
    );
    expect(cubit.state.canSave, isTrue);
    // Two mp3 files: none lossless.
    expect(find.text('No songs match'), findsOneWidget);
  });

  testWidgets('a rule removed counts again', (tester) async {
    final cubit = await pump(tester);
    cubit.addRule(const DurationBetween(max: Duration(minutes: 5)));
    await tester.pumpAndSettle();
    expect(find.text('1 song matches'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove this rule'));
    await tester.pumpAndSettle();
    expect(find.text('2 songs match'), findsOneWidget);
  });

  testWidgets('editing shows no templates and saves in place', (tester) async {
    const old = Playlist(
      id: 'p',
      name: 'Short',
      rules: SmartRules(rules: [DurationBetween(max: Duration(minutes: 5))]),
    );
    await pump(tester, playlist: old);
    expect(find.text('Start from'), findsNothing);
    expect(find.text('Under 5 min'), findsOneWidget);

    playlists.stored['p'] = old;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(playlists.created, isEmpty);
    expect(playlists.stored['p']!.rules, old.rules);
  });
}
