import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/data/backup_codec.dart';
import 'package:troona/features/backup/data/prefs_backup_preferences_repository.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_preferences.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_folder_repository.dart';
import 'package:troona/features/backup/domain/repositories/backup_preferences_repository.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/backup/domain/use_cases/run_auto_backup_use_case.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

Backup _backup({DateTime? at, List<BackupPlaylist> playlists = const []}) =>
    Backup(
      createdAt: at ?? DateTime.utc(2026, 11, 23),
      tracks: const {},
      playlists: playlists,
      plays: const [],
      days: const [],
      trackDays: const [],
      firstPlays: const [],
      replayMonth: null,
      settings: const AppSettings(),
    );

final class _Backups extends Fake implements BackupRepository {
  String fingerprintValue = 'f1';
  Set<BackupPart>? asked;
  Failure? fails;

  @override
  Future<Either<Failure, Backup>> snapshot(Set<BackupPart> parts) async {
    asked = parts;
    return fails == null ? right(_backup()) : left(fails!);
  }

  @override
  Future<String> fingerprint(Backup backup) async => fingerprintValue;
}

final class _Folder extends Fake implements BackupFolderRepository {
  BackupFolderState folder = const BackupFolderReady(
    BackupFolder(uri: 'tree:1', name: 'Troona'),
  );
  final stored = <StoredBackup>[];
  final deleted = <StoredBackup>[];
  Failure? saveFails;
  var _n = 0;

  StoredBackup add({
    required bool auto,
    required DateTime at,
    bool mine = true,
  }) {
    final b = StoredBackup(
      id: 'doc-${_n++}',
      name: 'b$_n',
      createdAt: at,
      auto: auto,
      mine: mine,
    );
    stored.add(b);
    return b;
  }

  @override
  Future<BackupFolderState> state() async => folder;

  @override
  Future<Either<Failure, List<StoredBackup>>> list() async =>
      right([...stored]..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  @override
  Future<Either<Failure, StoredBackup>> save(
    Backup backup, {
    required bool auto,
  }) async {
    if (saveFails case final f?) return left(f);
    return right(add(auto: auto, at: DateTime(2026, 11, 23, 12)));
  }

  @override
  Future<Either<Failure, Unit>> delete(StoredBackup backup) async {
    stored.remove(backup);
    deleted.add(backup);
    return right(unit);
  }

  @override
  BackupSummary? summaryOf(StoredBackup stored) => null;
}

final class _Preferences implements BackupPreferencesRepository {
  BackupPreferences value = const BackupPreferences(auto: true);
  AutoBackupMark? mark;

  @override
  BackupPreferences load() => value;

  @override
  Future<void> save(BackupPreferences preferences) async => value = preferences;

  @override
  AutoBackupMark? get lastAuto => mark;

  @override
  Future<void> setLastAuto(AutoBackupMark mark) async => this.mark = mark;

  @override
  DateTime? lastFailure;

  @override
  Future<void> setLastFailure(DateTime? at) async => lastFailure = at;
}

void main() {
  group('due', () {
    final evening = DateTime(2026, 11, 22, 21);
    AutoBackupMark at(DateTime t) => AutoBackupMark(at: t, fingerprint: 'f');

    test('the first one is due at once', () {
      expect(
        RunAutoBackupUseCase.isDue(null, BackupFrequency.weekly, evening),
        isTrue,
      );
    });

    test('daily: due the next calendar day, not 24 hours later', () {
      expect(
        RunAutoBackupUseCase.isDue(
          at(evening),
          BackupFrequency.daily,
          DateTime(2026, 11, 22, 23, 59),
        ),
        isFalse,
      );
      expect(
        RunAutoBackupUseCase.isDue(
          at(evening),
          BackupFrequency.daily,
          DateTime(2026, 11, 23, 8),
        ),
        isTrue,
      );
    });

    test('weekly: due seven days later', () {
      expect(
        RunAutoBackupUseCase.isDue(
          at(evening),
          BackupFrequency.weekly,
          DateTime(2026, 11, 28, 23),
        ),
        isFalse,
      );
      expect(
        RunAutoBackupUseCase.isDue(
          at(evening),
          BackupFrequency.weekly,
          DateTime(2026, 11, 29, 7),
        ),
        isTrue,
      );
    });

    test('a last backup in the future (clock set back) is due', () {
      expect(
        RunAutoBackupUseCase.isDue(
          at(DateTime(2027)),
          BackupFrequency.weekly,
          evening,
        ),
        isTrue,
      );
    });
  });

  group('running', () {
    late _Backups backups;
    late _Folder folder;
    late _Preferences preferences;
    final now = DateTime(2026, 11, 23, 12);

    RunAutoBackupUseCase useCase() => RunAutoBackupUseCase(
      backups: backups,
      folder: folder,
      preferences: preferences,
      now: () => now,
    );

    setUp(() {
      backups = _Backups();
      folder = _Folder();
      preferences = _Preferences();
    });

    test('off: nothing is read', () async {
      preferences.value = const BackupPreferences();

      expect(await useCase()(), const AutoBackupSkipped());
      expect(backups.asked, isNull);
    });

    test('not due: nothing is read', () async {
      preferences.mark = AutoBackupMark(at: now, fingerprint: 'f1');

      expect(await useCase()(), const AutoBackupSkipped());
      expect(backups.asked, isNull);
    });

    test(
      'due without a folder it can reach: says so, writes nothing',
      () async {
        folder.folder = const BackupFolderLost('Troona');

        expect(
          await useCase()(),
          const AutoBackupNoFolder(BackupFolderLost('Troona')),
        );
        expect(folder.stored, isEmpty);
        expect(preferences.mark, isNull);
      },
    );

    test('writes the parts chosen and marks the run', () async {
      preferences.value = const BackupPreferences(
        auto: true,
        parts: {BackupPart.likes},
      );

      final outcome = await useCase()();

      expect(outcome, isA<AutoBackupSaved>());
      expect(backups.asked, {BackupPart.likes});
      expect(folder.stored.single.auto, isTrue);
      expect(
        preferences.mark,
        AutoBackupMark(at: now, fingerprint: 'f1', name: 'b1'),
      );
    });

    test('nothing changed and the last one is there: no copy', () async {
      final last = folder.add(auto: true, at: DateTime(2026, 11, 1));
      preferences.mark = AutoBackupMark(
        at: DateTime(2026, 11, 1),
        fingerprint: 'f1',
        name: last.name,
      );

      expect(await useCase()(), const AutoBackupUnchanged());
      expect(folder.stored, hasLength(1));
      // Checked today: not due again until next week.
      expect(preferences.mark?.at, now);
      expect(preferences.mark?.name, last.name);
    });

    test('nothing changed but the last one was deleted, older ones kept: '
        'written again', () async {
      folder.add(auto: true, at: DateTime(2026, 10, 25));
      preferences.mark = AutoBackupMark(
        at: DateTime(2026, 11, 1),
        fingerprint: 'f1',
        name: 'gone.json',
      );

      expect(await useCase()(), isA<AutoBackupSaved>());
      expect(folder.stored.where((b) => b.auto), hasLength(2));
    });

    test('nothing changed but the file of that name is not ours (the other '
        'build\'s): written again', () async {
      final theirs = folder.add(
        auto: true,
        at: DateTime(2026, 11, 1),
        mine: false,
      );
      preferences.mark = AutoBackupMark(
        at: DateTime(2026, 11, 1),
        fingerprint: 'f1',
        name: theirs.name,
      );

      expect(await useCase()(), isA<AutoBackupSaved>());
    });

    test(
      'nothing changed but its backups were deleted: written again',
      () async {
        preferences.mark = AutoBackupMark(
          at: DateTime(2026, 11, 1),
          fingerprint: 'f1',
        );
        folder.add(auto: false, at: DateTime(2026, 11, 1));

        expect(await useCase()(), isA<AutoBackupSaved>());
      },
    );

    test('keeps the last five automatic ones, and every manual one', () async {
      final manual = folder.add(auto: false, at: DateTime(2026, 1, 1));
      final autos = [
        for (var day = 1; day <= 6; day++)
          folder.add(auto: true, at: DateTime(2026, 11, day)),
      ];

      await useCase()();

      // The two oldest go: five remain with the new one.
      expect(folder.deleted, [autos[1], autos[0]]);
      expect(folder.stored.where((b) => b.auto), hasLength(5));
      expect(folder.stored, contains(manual));
    });

    test(
      'rotation leaves the other build\'s automatic backups alone',
      () async {
        final theirs = [
          for (var day = 1; day <= 6; day++)
            folder.add(auto: true, at: DateTime(2026, 10, day), mine: false),
        ];
        final mine = [
          for (var day = 1; day <= 4; day++)
            folder.add(auto: true, at: DateTime(2026, 11, day)),
        ];

        await useCase()();

        // Four of ours and the new one: none to delete.
        expect(folder.deleted, isEmpty);
        expect(folder.stored, containsAll([...theirs, ...mine]));
      },
    );

    test(
      'a clock before 2024 (a phone reset to 1970) backs nothing up',
      () async {
        final useCase = RunAutoBackupUseCase(
          backups: backups,
          folder: folder,
          preferences: preferences,
          now: () => DateTime(1970, 1, 2),
        );

        expect(await useCase(), const AutoBackupSkipped());
        expect(backups.asked, isNull);
      },
    );

    test('after a failure, waits an hour before reading again', () async {
      preferences.lastFailure = now.subtract(const Duration(minutes: 59));

      expect(await useCase()(), const AutoBackupSkipped());
      expect(backups.asked, isNull);

      preferences.lastFailure = now.subtract(const Duration(hours: 1));
      expect(await useCase()(), isA<AutoBackupSaved>());
      // A success clears it.
      expect(preferences.lastFailure, isNull);
    });

    test('a failure marks nothing, so the next check tries again', () async {
      folder.saveFails = const BackupFolderLostFailure();

      expect(
        await useCase()(),
        const AutoBackupFailed(BackupFolderLostFailure()),
      );
      expect(preferences.mark, isNull);
      expect(folder.deleted, isEmpty);
      expect(preferences.lastFailure, now);
    });

    test('a snapshot that fails writes nothing', () async {
      backups.fails = const DatabaseFailure();

      expect(await useCase()(), const AutoBackupFailed(DatabaseFailure()));
      expect(folder.stored, isEmpty);
      expect(preferences.lastFailure, now);
    });

    test('a folder out of reach is not a failure to wait on', () async {
      folder.folder = const NoBackupFolder();

      await useCase()();

      expect(preferences.lastFailure, isNull);
    });
  });

  group('preferences', () {
    test('default to every part, off, weekly', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PrefsBackupPreferencesRepository(
        await SharedPreferences.getInstance(),
      );

      expect(repo.load(), const BackupPreferences());
      expect(repo.lastAuto, isNull);
    });

    test('read back as saved', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = PrefsBackupPreferencesRepository(
        await SharedPreferences.getInstance(),
      );
      const saved = BackupPreferences(
        parts: {BackupPart.history, BackupPart.settings},
        auto: true,
        frequency: BackupFrequency.daily,
      );
      final mark = AutoBackupMark(
        at: DateTime(2026, 11, 23, 3, 24),
        fingerprint: '0a1b',
        name: 'troona-auto-20261123-032400.json',
      );
      final failed = DateTime(2026, 11, 23, 4);

      await repo.save(saved);
      await repo.setLastAuto(mark);
      await repo.setLastFailure(failed);

      expect(repo.load(), saved);
      expect(repo.lastAuto, mark);
      expect(repo.lastFailure, failed);

      await repo.setLastFailure(null);
      await repo.setLastAuto(AutoBackupMark(at: mark.at, fingerprint: 'f'));
      expect(repo.lastFailure, isNull);
      expect(repo.lastAuto?.name, isNull);
    });

    test('a part a later version adds is kept until left out', () async {
      // Saved by a version that knew no equalizer part: it left history out.
      SharedPreferences.setMockInitialValues({
        PrefsBackupPreferencesRepository.partsLeftOutKey: <String>['history'],
      });
      final repo = PrefsBackupPreferencesRepository(
        await SharedPreferences.getInstance(),
      );

      expect(
        repo.load().parts,
        BackupPart.all.difference({BackupPart.history}),
      );
      expect(repo.load().parts, contains(BackupPart.equalizer));
    });

    test('broken values read as the defaults, never an empty backup', () async {
      SharedPreferences.setMockInitialValues({
        PrefsBackupPreferencesRepository.partsLeftOutKey: [
          for (final p in BackupPart.values) p.name,
        ],
        PrefsBackupPreferencesRepository.frequencyKey: 'hourly',
      });
      final repo = PrefsBackupPreferencesRepository(
        await SharedPreferences.getInstance(),
      );

      expect(repo.load(), const BackupPreferences());
    });
  });

  group('fingerprint', () {
    test('the same data on another day matches', () {
      expect(
        BackupCodec.fingerprint(_backup(at: DateTime.utc(2026, 1, 1))),
        BackupCodec.fingerprint(_backup(at: DateTime.utc(2026, 11, 23))),
      );
    });

    test('other data does not, and digits stay hex', () {
      final empty = BackupCodec.fingerprint(_backup());
      final liked = BackupCodec.fingerprint(
        _backup(
          playlists: const [
            BackupPlaylist(name: 'Liked', isLikes: true, tracks: []),
          ],
        ),
      );

      expect(liked, isNot(empty));
      expect(empty, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(liked, matches(RegExp(r'^[0-9a-f]{16}$')));
    });
  });
}
