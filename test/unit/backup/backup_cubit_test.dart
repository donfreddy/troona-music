import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
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
import 'package:troona/features/library/domain/repositories/library_repository.dart';

Backup _backup(Set<BackupPart> parts) => Backup(
  createdAt: DateTime.utc(2026, 11, 23),
  parts: parts,
  tracks: const {},
  playlists: const [BackupPlaylist(name: 'Mix', isLikes: false, tracks: [])],
  plays: const [],
  days: const [],
  trackDays: const [],
  firstPlays: const [],
  replayMonth: null,
  settings: null,
);

final class _Backups extends Fake implements BackupRepository {
  int clears = 0;
  int reads = 0;
  Set<BackupPart>? asked;

  @override
  Future<Either<Failure, Backup>> snapshot(Set<BackupPart> parts) async {
    asked = parts;
    return right(_backup(parts));
  }

  @override
  Future<String> fingerprint(Backup backup) async => 'f';

  @override
  Future<Either<Failure, String>> exportToFile(Backup backup) async =>
      right('/backup.json');

  @override
  Future<void> clearExports() async => clears++;

  @override
  Future<Either<Failure, Backup>> readFile(String path) async {
    reads++;
    return left(const BackupFormatFailure());
  }
}

final class _Folder extends Fake implements BackupFolderRepository {
  BackupFolderState folder = const NoBackupFolder();
  BackupFolder? toPick = const BackupFolder(uri: 'tree:1', name: 'Troona');
  final stored = <StoredBackup>[];
  int picks = 0;
  bool losesAccessOnList = false;

  @override
  Future<BackupFolderState> state() async => folder;

  @override
  Future<Either<Failure, BackupFolder?>> pick() async {
    picks++;
    if (toPick case final picked?) folder = BackupFolderReady(picked);
    return right(toPick);
  }

  @override
  Future<Either<Failure, List<StoredBackup>>> list() async {
    if (losesAccessOnList) {
      folder = const BackupFolderLost('Troona');
      return left(const BackupFolderLostFailure());
    }
    return right([...stored.reversed]);
  }

  @override
  Future<Either<Failure, StoredBackup>> save(
    Backup backup, {
    required bool auto,
  }) async {
    final b = StoredBackup(
      id: 'doc-${stored.length}',
      name: 'b${stored.length}',
      createdAt: DateTime(2026, 11, 23, stored.length),
      auto: auto,
    );
    stored.add(b);
    return right(b);
  }

  @override
  Future<Either<Failure, Backup>> read(StoredBackup stored) async =>
      right(_backup({BackupPart.playlists}));

  @override
  BackupSummary? summaryOf(StoredBackup stored) => null;
}

final class _Preferences implements BackupPreferencesRepository {
  BackupPreferences value = const BackupPreferences();
  AutoBackupMark? mark;

  @override
  BackupPreferences load() => value;

  @override
  Future<void> save(BackupPreferences preferences) async => value = preferences;

  @override
  AutoBackupMark? get lastAuto => mark;

  @override
  Future<void> setLastAuto(AutoBackupMark mark) async => this.mark = mark;
}

final class _Library extends Fake implements LibraryRepository {}

void main() {
  late _Backups backups;
  late _Folder folder;
  late _Preferences preferences;
  late BackupCubit cubit;

  setUp(() {
    backups = _Backups();
    folder = _Folder();
    preferences = _Preferences();
    cubit = BackupCubit(
      export: ExportBackupUseCase(backups),
      restore: RestoreBackupUseCase(backups, _Library()),
      save: SaveBackupUseCase(backups, folder),
      auto: RunAutoBackupUseCase(
        backups: backups,
        folder: folder,
        preferences: preferences,
      ),
      folder: folder,
      preferences: preferences,
    );
  });

  tearDown(() => cubit.close());

  test(
    'an export holds the parts chosen, and is deleted once shared',
    () async {
      await cubit.setParts({BackupPart.history});

      final result = await cubit.export((_) async {});

      expect(result.isRight(), isTrue);
      expect(backups.asked, {BackupPart.history});
      expect(backups.clears, 1);
      expect(cubit.state.busy, isFalse);
    },
  );

  test('the export is deleted when sharing fails', () async {
    final result = await cubit.export((_) async => throw StateError('no'));

    expect(result.isLeft(), isTrue);
    expect(backups.clears, 1);
  });

  test('a second task while one runs is refused', () async {
    final sharing = Completer<void>();
    final first = cubit.export((_) => sharing.future);
    await pumpEventQueue();

    final second = await cubit.openFile('/other.json');
    final auto = await cubit.autoBackupIfDue();
    sharing.complete();

    expect(second.isLeft(), isTrue);
    expect(auto, isNull);
    expect(backups.reads, 0);
    expect((await first).isRight(), isTrue);
  });

  test('turning it on without a folder asks for one, then backs up', () async {
    await cubit.setAuto(true);

    expect(folder.picks, 1);
    expect(cubit.state.preferences.auto, isTrue);
    expect(preferences.value.auto, isTrue);
    expect(cubit.state.backups.single.auto, isTrue);
    expect(cubit.state.lastAuto, cubit.state.backups.single);
  });

  test('cancelling the folder picker leaves it off', () async {
    folder.toPick = null;

    await cubit.setAuto(true);

    expect(cubit.state.preferences.auto, isFalse);
    expect(preferences.value.auto, isFalse);
    expect(folder.stored, isEmpty);
  });

  test('the parts are never left empty', () async {
    await cubit.setParts({});

    expect(cubit.state.preferences.parts, BackupPart.all);
  });

  test('a backup by hand joins the list', () async {
    folder.folder = const BackupFolderReady(
      BackupFolder(uri: 'tree:1', name: 'Troona'),
    );

    final saved = await cubit.backUpNow();

    expect(saved.isRight(), isTrue);
    expect(cubit.state.backups.single.auto, isFalse);
  });

  test('a backup read once is counted in the list', () async {
    folder.folder = const BackupFolderReady(
      BackupFolder(uri: 'tree:1', name: 'Troona'),
    );
    await cubit.backUpNow();
    final stored = cubit.state.backups.single;

    await cubit.open(stored);

    expect(cubit.state.summaries[stored.id]?.playlists, 1);
  });

  test('a folder whose access went while listing shows as lost', () async {
    folder.folder = const BackupFolderReady(
      BackupFolder(uri: 'tree:1', name: 'Troona'),
    );
    folder.losesAccessOnList = true;

    await cubit.load();

    expect(cubit.state.folder, const BackupFolderLost('Troona'));
    expect(cubit.state.backups, isEmpty);
  });
}
