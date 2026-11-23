import 'package:dartz/dartz.dart';
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
import 'package:troona/features/library/domain/repositories/library_repository.dart';
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
import 'package:troona/features/settings/presentation/pages/library_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/online_settings_page.dart';
import 'package:troona/features/settings/presentation/pages/settings_page.dart';
import 'package:troona/features/settings/presentation/pages/storage_settings_page.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/features/updates/domain/use_cases/check_for_update_use_case.dart';
import 'package:troona/features/updates/presentation/cubit/update_cubit.dart';
import 'package:troona/l10n/app_localizations.dart';

import '../../helpers/fake_player.dart';
import '../../helpers/roboto.dart';
import '../../unit/updates/update_fakes.dart';

final class _Maintenance extends Fake implements MaintenanceRepository {
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

final class _Library extends Fake implements LibraryRepository {
  @override
  void cancelScan() {}
}

void main() {
  setUpAll(loadRoboto);

  late SettingsCubit settings;
  late MaintenanceCubit maintenance;
  late BackupCubit backup;
  late UpdateCubit update;
  late LibraryBloc library;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = SettingsRepositoryImpl(await SharedPreferences.getInstance());
    settings = SettingsCubit(prefs);
    await settings.load();
    maintenance = MaintenanceCubit(_Maintenance());
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
    final updates = FakeUpdateRepository();
    update = UpdateCubit(
      check: CheckForUpdateUseCase(updates, FakeApp()),
      repo: updates,
      settings: prefs,
    );
    library = LibraryBloc(
      scanLibrary: ScanLibraryUseCase(_Library()),
      getTracks: GetTracksUseCase(_Library()),
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
  });

  Widget providers(Widget child) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: settings),
      BlocProvider.value(value: maintenance),
      BlocProvider.value(value: backup),
      BlocProvider.value(value: update),
      BlocProvider.value(value: library),
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

    testWidgets('says how things stand: extras off, the cache, the version', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(400, 1400);
      addTearDown(tester.view.reset);
      await pump(tester, const SettingsPage());

      expect(find.text('Off. Nothing leaves your phone.'), findsOneWidget);
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
      expect(
        onlineSummary(l10n, const AppSettings()),
        'Off. Nothing leaves your phone.',
      );
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

  testWidgets('resuming after a call waits for pausing during one', (
    tester,
  ) async {
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

    expect(resume().enabled, isTrue);

    await settings.setStopOnCall(false);
    await tester.pumpAndSettle();

    expect(resume().enabled, isFalse);
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
