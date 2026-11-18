import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/di/injection.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/presentation/bloc/home_bloc.dart';
import 'package:troona/features/home/presentation/pages/home_page.dart';
import 'package:troona/features/home/presentation/widgets/home_system_card.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/updates/domain/entities/app_release.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/l10n/app_localizations_en.dart';
import 'package:troona/l10n/app_localizations_fr.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';

class _Updates extends Cubit<UpdateState> implements UpdateCubit {
  _Updates(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings extends Cubit<SettingsState> implements SettingsCubit {
  _Settings(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

HomeLoaded _home({int weeklyPlays = 0, bool listened = true}) => HomeLoaded(
  HomeFeed(
    recentlyPlayed: listened ? [testTrack('1', durationMs: 60000)] : const [],
    yourArtists: const [],
    newAlbums: const [],
    weeklyPlayCount: weeklyPlays,
  ),
  totalTracks: 40,
);

void main() {
  group('subtitle', () {
    final en = AppLocalizationsEn();

    test("this week's plays, the one figure Home keeps", () {
      expect(
        HomePage.subtitleOf(en, _home(weeklyPlays: 12)),
        '12 plays this week',
      );
      expect(
        HomePage.subtitleOf(en, _home(weeklyPlays: 1)),
        '1 play this week',
      );
      expect(
        HomePage.subtitleOf(AppLocalizationsFr(), _home(weeklyPlays: 12)),
        '12 écoutes cette semaine',
      );
    });

    test('none this week yet: the plain line', () {
      expect(HomePage.subtitleOf(en, _home()), en.homeSubtitleWarm);
    });

    test('nothing ever played: no subtitle, the hero card says it', () {
      expect(HomePage.subtitleOf(en, _home(listened: false)), isNull);
    });
  });

  group('system card', () {
    final release = AppRelease(
      version: '9.9.9',
      page: Uri.parse('https://example.org'),
    );
    final en = AppLocalizationsEn();

    Future<void> pump(
      WidgetTester tester, {
      required UpdateState update,
      bool offered = false,
      bool offerExtras = true,
    }) async {
      final updates = _Updates(update);
      final settings = _Settings(
        SettingsLoaded(AppSettings(onlineExtrasOffered: offered)),
      );
      getIt
        ..registerSingleton<UpdateCubit>(updates)
        ..registerSingleton<SettingsCubit>(settings);
      addTearDown(() async {
        await getIt.reset();
        await updates.close();
        await settings.close();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeSystemCard(offerExtras: offerExtras),
            ),
          ),
        ),
      );
    }

    testWidgets('a new release takes the place of the offer', (tester) async {
      await pump(tester, update: UpdateState(available: release));
      expect(find.text(en.updateAvailable('9.9.9')), findsOneWidget);
      expect(find.text(en.homeExtrasTitle), findsNothing);
    });

    testWidgets('without one, the offer', (tester) async {
      await pump(tester, update: const UpdateState());
      expect(find.text(en.homeExtrasTitle), findsOneWidget);
    });

    testWidgets('a skipped release leaves the offer its place', (tester) async {
      await pump(
        tester,
        update: UpdateState(available: release, skipped: '9.9.9'),
      );
      expect(find.text(en.homeExtrasTitle), findsOneWidget);
    });

    testWidgets('an empty library is offered nothing', (tester) async {
      await pump(tester, update: const UpdateState(), offerExtras: false);
      expect(find.text(en.homeExtrasTitle), findsNothing);
    });

    testWidgets('an offer already answered shows nothing', (tester) async {
      await pump(tester, update: const UpdateState(), offered: true);
      expect(find.text(en.homeExtrasTitle), findsNothing);
    });
  });
}
