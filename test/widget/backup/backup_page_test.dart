import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/theme/app_theme.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
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
import 'package:troona/features/backup/presentation/pages/backup_page.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:troona/l10n/app_localizations.dart';
import 'package:troona/features/settings/presentation/widgets/settings_tile.dart';
import 'package:troona/shared/widgets/app_button.dart';

import '../../helpers/roboto.dart';

/// A backup holding playlists and settings, nothing else.
final _saved = Backup(
  createdAt: DateTime.utc(2026, 11, 20, 9),
  parts: const {BackupPart.playlists, BackupPart.settings},
  tracks: const {},
  playlists: const [BackupPlaylist(name: 'Mix', isLikes: false, tracks: [])],
  plays: const [],
  days: const [],
  trackDays: const [],
  firstPlays: const [],
  replayMonth: null,
  settings: const AppSettings(hapticFeedbackEnabled: false),
);

final class _Backups extends Fake implements BackupRepository {
  Backup? restored;

  @override
  Future<Either<Failure, Unit>> restore(
    Backup backup,
    Map<String, String> ids,
  ) async {
    restored = backup;
    return right(unit);
  }
}

final class _Folder extends Fake implements BackupFolderRepository {
  _Folder(this.folder);

  final BackupFolderState folder;

  /// Holds the folder's check until completed.
  Completer<void>? gate;
  final backups = [
    StoredBackup(
      id: 'a',
      name: 'troona-auto-20261122-090000.json',
      createdAt: DateTime(2026, 11, 22, 9),
      auto: true,
    ),
    StoredBackup(
      id: 'm',
      name: 'troona-backup-20261120-090000.json',
      createdAt: DateTime(2026, 11, 20, 9),
      auto: false,
    ),
  ];

  @override
  Future<BackupFolderState> state() async {
    await gate?.future;
    return folder;
  }

  @override
  Future<Either<Failure, List<StoredBackup>>> list() async => right(backups);

  @override
  BackupSummary? summaryOf(StoredBackup stored) => stored.auto
      ? const BackupSummary(
          parts: BackupPart.all,
          playlists: 12,
          likes: 1480,
          plays: 23450,
        )
      : null;

  @override
  Future<Either<Failure, Backup>> read(StoredBackup stored) async =>
      right(_saved);
}

final class _Preferences extends Fake implements BackupPreferencesRepository {
  @override
  BackupPreferences load() =>
      const BackupPreferences(auto: true, frequency: BackupFrequency.daily);
}

final class _Library extends Fake implements LibraryRepository {
  @override
  Future<Either<Failure, List<Track>>> getTracks() async => right(const []);
}

/// The liked songs, counting how often they are read again.
final class _LikesRepo extends Fake implements LibraryRepository {
  int loads = 0;

  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async {
    loads++;
    return right(const Playlist(id: Playlist.likesId, name: 'Likes'));
  }
}

void main() {
  setUpAll(loadRoboto);

  late _Backups backups;
  late SettingsCubit settings;
  late _LikesRepo likesRepo;
  late LikesCubit likes;

  setUp(() async {
    backups = _Backups();
    likesRepo = _LikesRepo();
    likes = LikesCubit(
      addTrack: AddTrackToLikesUseCase(likesRepo),
      removeTrack: RemoveTrackFromLikesUseCase(likesRepo),
      isTrackLiked: IsTrackInLikesUseCase(likesRepo),
      getLikesPlaylist: GetLikesPlaylistUseCase(likesRepo),
    );
    SharedPreferences.setMockInitialValues({});
    settings = SettingsCubit(
      SettingsRepositoryImpl(await SharedPreferences.getInstance()),
    );
    await settings.load();
  });

  tearDown(() async {
    await settings.close();
    await likes.close();
  });

  Future<BackupCubit> pump(
    WidgetTester tester, {
    BackupFolderState folder = const BackupFolderReady(
      BackupFolder(uri: 'tree:1', name: 'Troona backups on the SD card'),
    ),
    Locale locale = const Locale('en'),
    Completer<void>? gate,
  }) async {
    final repoFolder = _Folder(folder)..gate = gate;
    final preferences = _Preferences();
    final cubit = BackupCubit(
      export: ExportBackupUseCase(backups),
      restore: RestoreBackupUseCase(backups, _Library()),
      save: SaveBackupUseCase(backups, repoFolder),
      auto: RunAutoBackupUseCase(
        backups: backups,
        folder: repoFolder,
        preferences: preferences,
      ),
      folder: repoFolder,
      preferences: preferences,
    );
    addTearDown(cubit.close);
    if (gate == null) await cubit.load();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: settings),
          BlocProvider.value(value: likes),
        ],
        child: MaterialApp(
          theme: robotoTheme(AppTheme.dark),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BackupPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  for (final locale in const [Locale('en'), Locale('fr')]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('${locale.languageCode}, 360 x 640, text x$scale: '
          'nothing overflows', (tester) async {
        tester.view
          ..devicePixelRatio = 3
          ..physicalSize = const Size(360, 640) * 3;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await pump(tester, locale: locale);
        // Down to the last row, built and laid out.
        await tester.scrollUntilVisible(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(BackupPage)),
            ).backupFromFile,
          ),
          300,
          scrollable: find.byType(Scrollable).first,
        );

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('lists the backups, the automatic one marked and counted', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Auto'), findsOneWidget);
    expect(
      find.text('12 playlists, 1480 liked songs, 23450 plays'),
      findsOneWidget,
    );
    expect(find.text('Troona backups on the SD card'), findsOneWidget);
  });

  testWidgets('without a folder to pick, no automatic backup is offered', (
    tester,
  ) async {
    await pump(tester, folder: const BackupFolderUnsupported());

    expect(find.text('Back up automatically'), findsNothing);
    expect(find.text('Back up now'), findsOneWidget);
  });

  testWidgets('until the folder is checked, nothing that needs it can be '
      'tapped', (tester) async {
    final gate = Completer<void>();
    final cubit = await pump(tester, gate: gate);
    SettingsTile tile(String title) => tester.widget<SettingsTile>(
      find.ancestor(of: find.text(title), matching: find.byType(SettingsTile)),
    );

    expect(cubit.state.folderRead, isFalse);
    expect(tile('Back up now').onTap, isNull);

    gate.complete();
    await tester.pumpAndSettle();

    expect(tile('Back up now').onTap, isNotNull);
  });

  testWidgets('with its folder lost, Back up now says so and shares nothing', (
    tester,
  ) async {
    await pump(tester, folder: const BackupFolderLost('Troona'));

    // On the folder row and under Back up now.
    expect(find.text("Can't reach Troona. Choose it again."), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Back up now'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Back up now'));
    await tester.pump();

    // The fake repository throws on a snapshot: none was taken.
    expect(tester.takeException(), isNull);
    expect(
      find.text("Can't reach the backup folder. Choose it again."),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a restore offers the parts the backup holds, and writes the '
      'ones left ticked', (tester) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(400, 900) * 3;
    addTearDown(tester.view.reset);
    await pump(tester);

    final likesRead = likesRepo.loads;
    // The time's space before AM is a narrow no-break one, as intl writes it.
    await tester.tap(find.textContaining('Nov 20, 2026'));
    await tester.pumpAndSettle();

    // Only what it holds: no likes, no history, no equalizer.
    expect(find.text('Restore this backup'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('Liked songs'), findsNothing);
    expect(find.text('Listening history'), findsNothing);

    await tester.tap(find.text('They replace yours'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AppButton),
        matching: find.text('Restore'),
      ),
    );
    await tester.pumpAndSettle();

    expect(backups.restored?.parts, {BackupPart.playlists});
    expect(
      settings.state.mapOrNull(loaded: (s) => s.settings.hapticFeedbackEnabled),
      isTrue,
    );
    // The likes were not restored: not read again.
    expect(likesRepo.loads, likesRead);
    expect(find.text('Backup restored'), findsOneWidget);
  });
}
