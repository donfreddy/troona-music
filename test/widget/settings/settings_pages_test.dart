import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/router/app_router.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/backup/domain/entities/backup_preferences.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_folder_repository.dart';
import 'package:troona/features/backup/domain/repositories/backup_preferences_repository.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/backup/domain/use_cases/export_backup_use_case.dart';
import 'package:troona/features/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:troona/features/backup/domain/use_cases/run_auto_backup_use_case.dart';
import 'package:troona/features/backup/domain/use_cases/save_backup_use_case.dart';
import 'package:troona/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:troona/features/equalizer/data/repositories/prefs_equalizer_repository.dart';
import 'package:troona/features/equalizer/presentation/cubit/equalizer_cubit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/repositories/stored_track_repository.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_use_case.dart';
import 'package:troona/features/library/domain/use_cases/scan_library_use_case.dart';
import 'package:troona/features/library/presentation/bloc/library/library_bloc.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/maintenance_repository.dart';
import 'package:troona/features/settings/presentation/cubit/maintenance_cubit.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/features/settings/presentation/pages/about_page.dart';
import 'package:troona/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/audio_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/library_folders_page.dart';
import 'package:troona/features/settings/presentation/pages/library_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/licenses_page.dart';
import 'package:troona/features/settings/presentation/utils/license_catalog.dart';
import 'package:troona/features/settings/presentation/pages/online_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/settings_page.dart';
import 'package:troona/features/settings/presentation/pages/storage_settings_page.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/features/updates/domain/use_cases/check_for_update_use_case.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/shared/widgets/app_back_button.dart';
import 'package:troona/services/scanner/media_scanner_service.dart';

import '../../helpers/fake_equalizer.dart';
import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';
import '../../unit/updates/update_fakes.dart';

final class _Maintenance extends Fake implements MaintenanceRepository {
  int coverClears = 0;

  @override
  Future<Either<Failure, Unit>> clearCovers() async {
    coverClears++;
    return right(unit);
  }

  @override
  Future<AppVersion> appVersion() async =>
      const AppVersion(version: '1.9.0', build: '42');

  @override
  Future<CacheSizes> cacheSizes() async => const CacheSizes(
    coverBytes: 30 * 1024 * 1024,
    onlineInfoBytes: 12 * 1024 * 1024 + 300 * 1024,
  );
}

final class _Folder extends Fake implements BackupFolderRepository {
  @override
  Future<BackupFolderState> state() async => const NoBackupFolder();

  @override
  Future<Either<Failure, List<StoredBackup>>> list() async => right(const []);

  @override
  BackupSummary? summaryOf(StoredBackup stored) => null;
}

final class _Preferences extends Fake implements BackupPreferencesRepository {
  @override
  BackupPreferences load() => const BackupPreferences();
}

final class _Backups extends Fake implements BackupRepository {}

final class _Library extends Fake
    implements LibraryRepository, StoredTrackRepository {
  /// What the phone stores, the songs left out included.
  List<Track> stored = [testTrack('1', durationMs: 1000)];

  @override
  Future<Either<Failure, List<Track>>> getStoredTracks() async => right(stored);

  int scans = 0;

  @override
  void cancelScan() {}

  @override
  Future<Either<Failure, Stream<ScanProgress>>> scanLibrary() async {
    scans++;
    return right(const Stream.empty());
  }

  @override
  Future<Either<Failure, List<Track>>> getTracks() async =>
      right([testTrack('1', durationMs: 1000)]);
}

void main() {
  setUpAll(loadRoboto);

  late SettingsCubit settings;
  late MaintenanceCubit maintenance;
  late BackupCubit backup;
  late UpdateCubit update;
  late LibraryBloc library;
  late EqualizerCubit equalizer;
  late _Maintenance maintenanceRepo;
  late _Library libraryRepo;
  late FakeUpdateRepository updates;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = SettingsRepositoryImpl(await SharedPreferences.getInstance());
    settings = SettingsCubit(prefs);
    await settings.load();
    maintenanceRepo = _Maintenance();
    libraryRepo = _Library();
    maintenance = MaintenanceCubit(maintenanceRepo);
    final eqRepo = PrefsEqualizerRepository(
      await SharedPreferences.getInstance(),
    );
    await eqRepo.saveLayout(fiveBands);
    equalizer = EqualizerCubit(
      port: FakeEqualizerPort(supported: true),
      repo: eqRepo,
    )..start();
    final folder = _Folder();
    final preferences = _Preferences();
    backup = BackupCubit(
      export: ExportBackupUseCase(_Backups()),
      restore: RestoreBackupUseCase(_Backups(), _Library()),
      save: SaveBackupUseCase(_Backups(), folder),
      auto: RunAutoBackupUseCase(
        backups: _Backups(),
        folder: folder,
        preferences: preferences,
      ),
      folder: folder,
      preferences: preferences,
    );
    updates = FakeUpdateRepository();
    update = UpdateCubit(
      check: CheckForUpdateUseCase(updates, FakeApp()),
      repo: updates,
      settings: prefs,
    );
    library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(libraryRepo),
      getTracks: GetTracksUseCase(libraryRepo),
    );
    final tracks = [
      testTrack('1', durationMs: 1000),
      testTrack('2', durationMs: 1000),
    ];
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    library.emit(
      LibraryLoaded(
        allTracks: tracks,
        allAlbums: const [],
        allArtists: const [],
        visibleTracks: tracks,
        visibleAlbums: const [],
        visibleArtists: const [],
      ),
    );
  });

  tearDown(() async {
    await settings.close();
    await maintenance.close();
    await backup.close();
    await update.close();
    await library.close();
    await equalizer.close();
  });

  Widget providers(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: settings),
      BlocProvider.value(value: maintenance),
      BlocProvider.value(value: backup),
      BlocProvider.value(value: update),
      BlocProvider.value(value: library),
      BlocProvider.value(value: equalizer),
    ],
    child: child,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      providers(
        MaterialApp(
          theme: robotoTheme(AppTheme.dark),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final pages = <String, Widget Function()>{
    'root': () => const SettingsPage(),
    'audio': () => const AudioSettingsPage(),
    'library': () => const LibrarySettingsPage(),
    'online': () => const OnlineSettingsPage(),
    'appearance': () => const AppearanceSettingsPage(),
    'storage': () => const StorageSettingsPage(),
    'about': () => const AboutPage(),
  };

  for (final MapEntry(key: name, value: page) in pages.entries) {
    for (final locale in const [Locale('en'), Locale('fr')]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('$name, ${locale.languageCode}, 360 x 640, text x$scale: '
            'nothing overflows', (tester) async {
          tester.view
            ..devicePixelRatio = 3
            ..physicalSize = const Size(360, 640) * 3;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await pump(tester, page(), locale: locale);
          // Down to the end, every row built and laid out.
          final scrollable = find.byType(Scrollable).first;
          for (var i = 0; i < 20; i++) {
            await tester.drag(scrollable, const Offset(0, -400));
            await tester.pump();
          }
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  group('folders', () {
    /// The phone stores [ids]; the library holds the ones not left out.
    void holding(List<String> ids) {
      final tracks = [for (final id in ids) testTrack(id, durationMs: 60000)];
      libraryRepo.stored = tracks;
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      library.emit(
        LibraryLoaded(
          allTracks: tracks,
          allAlbums: const [],
          allArtists: const [],
          visibleTracks: tracks,
          visibleAlbums: const [],
          visibleArtists: const [],
        ),
      );
    }

    List<String>? excluded() => switch (settings.state) {
      SettingsLoaded(:final settings) => settings.excludedFolders,
      _ => null,
    };

    CupertinoSwitch switchOf(WidgetTester tester, String folder) =>
        tester.widget<CupertinoSwitch>(
          find.descendant(
            of: find.byKey(ValueKey(folder)),
            matching: find.byType(CupertinoSwitch),
          ),
        );

    Widget page() => LibraryFoldersPage(stored: libraryRepo);

    testWidgets('a folder turned off is saved at once, its songs counted', (
      tester,
    ) async {
      holding(['rap/1', 'rap/2', 'voice/1']);
      await pump(tester, page());

      expect(find.text('2 songs, /music'), findsOneWidget);
      await tester.tap(find.text('voice'));
      await tester.pumpAndSettle();

      expect(excluded(), ['/music/voice']);
      expect(switchOf(tester, '/music/voice').value, isFalse);
      // Left out, its songs are still stored and counted.
      expect(find.text('1 song, /music'), findsOneWidget);
    });

    testWidgets('the last songs in cannot be left out', (tester) async {
      holding(['rap/1', 'voice/1']);
      await settings.setExcludedFolders({'/music/voice'});
      await pump(tester, page());

      expect(switchOf(tester, '/music/rap').onChanged, isNull);
      expect(switchOf(tester, '/music/voice').onChanged, isNotNull);
    });

    testWidgets('nor through a folder holding the only other one', (
      tester,
    ) async {
      holding(['rap/1', 'rap/live/1']);
      await pump(tester, page());

      // Turning off rap would take live with it: nothing would be left.
      expect(switchOf(tester, '/music/rap').onChanged, isNull);
      expect(switchOf(tester, '/music/rap/live').onChanged, isNotNull);
    });

    testWidgets('nor by a length no song reaches', (tester) async {
      holding(['rap/1', 'pop/1']);
      await pump(tester, const LibrarySettingsPage());

      await tester.tap(find.text('2 min'));
      await tester.pump();

      expect(
        find.text('No song in your library is that long: it would be empty.'),
        findsOneWidget,
      );
      expect(
        settings.state,
        isA<SettingsLoaded>().having(
          (s) => s.settings.minTrackSeconds,
          'length',
          10,
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('a subfolder of a folder left out says so and waits', (
      tester,
    ) async {
      holding(['rap/1', 'rap/live/1', 'pop/1']);
      await pump(tester, page());

      await tester.tap(find.text('rap'));
      await tester.pumpAndSettle();

      expect(find.text('Left out with rap, /music/rap'), findsOneWidget);
      expect(switchOf(tester, '/music/rap/live').value, isFalse);
      expect(switchOf(tester, '/music/rap/live').onChanged, isNull);

      // Back on, it saves no folder under it.
      await tester.tap(find.text('rap'));
      await tester.pumpAndSettle();
      expect(excluded(), isEmpty);
    });

    testWidgets('the root of the phone is named after it', (tester) async {
      libraryRepo.stored = [
        Track(
          id: '1',
          title: 'Title 1',
          artist: 'Artist',
          artistId: 1,
          album: 'Album',
          albumId: 1,
          path: '/storage/emulated/0/song.mp3',
          uri: 'content://1',
          size: 1,
          durationMs: 60000,
          fileName: 'song.mp3',
        ),
        testTrack('2', durationMs: 60000),
      ];
      await pump(tester, page());

      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('1 song'), findsOneWidget);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('fr, 360 x 640, text x$scale: nothing overflows', (
        tester,
      ) async {
        tester.view
          ..devicePixelRatio = 3
          ..physicalSize = const Size(360, 640) * 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        holding([
          'Téléchargements de musique pour la voiture/1',
          'Albums complets en haute définition/sous-dossier très long/2',
          'x/3',
        ]);
        await settings.setExcludedFolders({'/music/x'});

        await pump(tester, page(), locale: const Locale('fr'));
        // Dragged by the left edge, away from the switches.
        for (var i = 0; i < 10; i++) {
          await tester.dragFrom(const Offset(8, 500), const Offset(0, -400));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('licenses', () {
    setUp(() {
      LicenseRegistry.reset();
      LicenseCatalog.reset();
      LicenseCatalog.run = <M, R>(callback, message, {debugLabel}) async =>
          callback(message);
      LicenseRegistry.addLicense(
        () => Stream.fromIterable(const [
          LicenseEntryWithLineBreaks(
            ['on_audio_query_platform_interface', 'go_router'],
            'Permission is hereby granted, free of charge, to any person.\n\n'
            'THE SOFTWARE IS PROVIDED "AS IS".',
          ),
          LicenseEntryWithLineBreaks(['lucide'], 'Terms written by hand.'),
        ]),
      );
    });

    tearDown(() {
      LicenseRegistry.reset();
      LicenseCatalog.reset();
      LicenseCatalog.run = compute;
    });

    testWidgets('a license opens on its own page, in the app', (tester) async {
      final router = GoRouter(
        initialLocation: '/licenses',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const SizedBox(),
            routes: [
              GoRoute(
                path: 'licenses',
                name: AppRoute.settingsLicenses,
                builder: (_, _) => const LicensesPage(),
                routes: [
                  GoRoute(
                    path: ':index',
                    name: AppRoute.settingsLicense,
                    builder: (_, state) => LicenseDetailPage(
                      index: int.parse(state.pathParameters['index']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        providers(
          MaterialApp.router(
            theme: robotoTheme(AppTheme.dark),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // One row per package, in sections by initial.
      expect(find.text('G'), findsOneWidget);
      expect(find.text('go_router'), findsOneWidget);
      expect(find.text('on_audio_query_platform_interface'), findsOneWidget);
      expect(find.text('MIT'), findsNWidgets(2));
      expect(find.text('lucide'), findsOneWidget);
      expect(find.text('Its own terms'), findsOneWidget);

      await tester.tap(find.text('go_router'));
      await tester.pumpAndSettle();

      expect(find.text('go_router'), findsWidgets);
      expect(find.text('THE SOFTWARE IS PROVIDED "AS IS".'), findsOneWidget);
      expect(find.byType(AppBackButton), findsOneWidget);
    });

    testWidgets('a place no longer listed says so', (tester) async {
      await pump(tester, const LicenseDetailPage(index: 9));

      expect(find.text('This license is no longer listed.'), findsOneWidget);
    });

    for (final locale in const [Locale('en'), Locale('fr')]) {
      testWidgets(
        '${locale.languageCode}, 360 x 640, text x2.0: nothing overflows',
        (tester) async {
          tester.view
            ..devicePixelRatio = 3
            ..physicalSize = const Size(360, 640) * 3;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await pump(tester, const LicensesPage(), locale: locale);
          expect(tester.takeException(), isNull);
          await pump(tester, const LicenseDetailPage(index: 0), locale: locale);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('root', () {
    testWidgets('each category opens its page', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 1400);
      addTearDown(tester.view.reset);
      const names = [
        AppRoute.settingsAudio,
        AppRoute.settingsLibrary,
        AppRoute.settingsOnline,
        AppRoute.settingsAppearance,
        AppRoute.backup,
        AppRoute.settingsStorage,
        AppRoute.settingsAbout,
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const SettingsPage(),
            routes: [
              for (final name in names)
                GoRoute(
                  path: name,
                  name: name,
                  builder: (_, _) => Scaffold(body: Text('page $name')),
                ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        providers(
          MaterialApp.router(
            theme: robotoTheme(AppTheme.dark),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      const titles = {
        AppRoute.settingsAudio: 'Audio',
        AppRoute.settingsLibrary: 'Library',
        AppRoute.settingsOnline: 'Online extras',
        AppRoute.settingsAppearance: 'Appearance',
        AppRoute.backup: 'Backup & restore',
        AppRoute.settingsStorage: 'Storage',
        AppRoute.settingsAbout: 'About',
      };
      for (final MapEntry(key: name, value: title) in titles.entries) {
        await tester.tap(
          find.descendant(
            of: find.byType(SettingsTile),
            matching: find.text(title),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('page $name'), findsOneWidget, reason: title);
        router.pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the privacy policy opens from Online extras', (tester) async {
      final router = GoRouter(
        initialLocation: '/online',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const SizedBox(),
            routes: [
              GoRoute(
                path: 'online',
                builder: (_, _) => const OnlineSettingsPage(),
              ),
              GoRoute(
                path: 'privacy',
                name: AppRoute.privacy,
                builder: (_, _) => const Scaffold(body: Text('page privacy')),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        providers(
          MaterialApp.router(
            theme: robotoTheme(AppTheme.dark),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Privacy policy'), 100);
      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();

      expect(find.text('page privacy'), findsOneWidget);
    });

    testWidgets('says how things stand: extras off, the cache, the version', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 1400);
      addTearDown(tester.view.reset);
      await pump(tester, const SettingsPage());

      // Off, not "nothing leaves": the update check is elsewhere.
      expect(find.text('Off'), findsOneWidget);
      // Both caches together.
      expect(find.text('Cache 42.3 MB, reset'), findsOneWidget);
      expect(find.text("Version 1.9.0, what's new, updates"), findsOneWidget);
    });
  });

  group('online summary', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('off when none is on', () {
      expect(onlineSummary(l10n, const AppSettings()), 'Off');
    });

    test('names the ones on, in their order', () {
      expect(
        onlineSummary(
          l10n,
          const AppSettings(fetchOnlineMetadata: true, fetchLyrics: true),
        ),
        'On: bios, lyrics',
      );
    });
  });

  testWidgets('resuming after a call stays its own switch, as the service '
      'reads it', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 1400);
    addTearDown(tester.view.reset);
    await pump(tester, const AudioSettingsPage());
    SettingsTile resume() => tester.widget<SettingsTile>(
      find.ancestor(
        of: find.text('Resume after calls'),
        matching: find.byType(SettingsTile),
      ),
    );

    await settings.setStopOnCall(false);
    await tester.pumpAndSettle();

    // The service resumes whatever the pause switch says (and iOS pauses
    // for calls on its own): it must stay reachable.
    expect(resume().enabled, isTrue);
  });

  testWidgets('Audio offers the equalizer on a phone that has one', (
    tester,
  ) async {
    await pump(tester, const AudioSettingsPage());

    expect(find.text('Equalizer'), findsOneWidget);
  });

  testWidgets('clearing the covers asks first, then clears and says so', (
    tester,
  ) async {
    await pump(tester, const StorageSettingsPage());

    await tester.tap(find.text('Clear cover cache'));
    await tester.pumpAndSettle();
    expect(maintenanceRepo.coverClears, 0);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(maintenanceRepo.coverClears, 1);
    // The covers are extracted again by a scan, which starts once the
    // previous one is cancelled (real time, not the test's clock): up to
    // a second, so a busy machine has room.
    await tester.runAsync(() async {
      for (var i = 0; i < 100 && libraryRepo.scans == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    expect(libraryRepo.scans, 1);
    expect(find.text('Cover cache cleared'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('resetting turns the equalizer off and the settings back', (
    tester,
  ) async {
    await settings.setHapticFeedback(false);
    equalizer.setEnabled(true);
    expect(equalizer.state.settings.enabled, isTrue);
    await pump(tester, const StorageSettingsPage());

    await tester.tap(find.text('Reset settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(
      settings.state,
      isA<SettingsLoaded>().having(
        (s) => s.settings.hapticFeedbackEnabled,
        'haptics',
        isTrue,
      ),
    );
    expect(equalizer.state.settings.enabled, isFalse);
  });

  testWidgets('checking now says when Troona is up to date', (tester) async {
    updates.latest = release('1.0.0');
    await pump(tester, const AboutPage());

    await tester.tap(find.text('Check for updates now'));
    await tester.pumpAndSettle();

    expect(updates.fetches, 1);
    expect(find.text('Troona is up to date'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('About reads the version when opened first', (tester) async {
    await pump(tester, const AboutPage());

    expect(find.text('Version 1.9.0 (42)'), findsOneWidget);
  });

  testWidgets('sizes are written as the language writes them', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 1400);
    addTearDown(tester.view.reset);
    await pump(tester, const StorageSettingsPage(), locale: const Locale('fr'));

    expect(find.text('30,0 Mo'), findsOneWidget);
  });

  testWidgets('the library page counts the songs', (tester) async {
    await pump(tester, const LibrarySettingsPage());

    expect(find.text('2 songs'), findsOneWidget);
  });

  testWidgets('starting over is marked as such', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 1400);
    addTearDown(tester.view.reset);
    await pump(tester, const StorageSettingsPage());

    for (final title in ['Clear queue and position', 'Reset settings']) {
      final tile = tester.widget<SettingsTile>(
        find.ancestor(
          of: find.text(title),
          matching: find.byType(SettingsTile),
        ),
      );
      expect(tile.destructive, isTrue, reason: title);
    }
    expect(find.text('30.0 MB'), findsOneWidget);
  });
}
