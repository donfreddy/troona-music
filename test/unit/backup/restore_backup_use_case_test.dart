import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_settings.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_snapshot.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';

import '../../helpers/fake_player.dart';

BackupTrack _saved(String id, {String? fileName}) => BackupTrack(
  title: 'Title $id',
  artist: 'Artist',
  album: 'Album',
  durationMs: 200000,
  fileName: fileName ?? '$id.mp3',
  size: 1,
);

final _backup = Backup(
  createdAt: DateTime(2026),
  tracks: {
    'k1': _saved('a'),
    'k2': _saved('zz', fileName: 'gone.mp3'),
  },
  playlists: const [
    BackupPlaylist(name: 'Liked', isLikes: true, tracks: ['k1', 'k2']),
  ],
  plays: const [],
  days: const [],
  trackDays: const [],
  firstPlays: const [],
  replayMonth: null,
  settings: const AppSettings(fetchOnlineMetadata: true),
);

final class _Backups implements BackupRepository {
  _Backups(this.file);

  final Either<Failure, Backup> file;
  Backup? restored;
  Map<String, String>? restoredIds;

  @override
  Future<Either<Failure, Backup>> readFile(String path) async => file;

  @override
  Future<Either<Failure, Unit>> restore(
    Backup backup,
    Map<String, String> ids,
  ) async {
    restored = backup;
    restoredIds = ids;
    return right(unit);
  }

  @override
  Future<Either<Failure, Backup>> snapshot(Set<BackupPart> parts) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, String>> exportToFile(Backup backup) =>
      throw UnimplementedError();

  @override
  Future<String> fingerprint(Backup backup) => throw UnimplementedError();

  @override
  Future<void> clearExports() async {}
}

final class _Library extends Fake implements LibraryRepository {
  @override
  Future<Either<Failure, List<Track>>> getTracks() async =>
      right([testTrack('a', durationMs: 200000)]);
}

RestoreBackupUseCase _useCase(_Backups backups) =>
    RestoreBackupUseCase(backups, _Library());

RestoreReport _report(Either<Failure, RestoreReport> result) =>
    result.getOrElse(() => throw StateError('failed'));

void main() {
  test('restores the songs found and reports the others', () async {
    final backups = _Backups(right(_backup));

    final report = _report(await _useCase(backups)(_backup, BackupPart.all));

    expect(backups.restoredIds, {'k1': 'a'});
    expect(report.found, 1);
    expect(report.total, 2);
    expect(report.missing.single.fileName, 'gone.mp3');
    expect(report.settings?.fetchOnlineMetadata, isTrue);
  });

  test(
    'the equalizer of the backup comes back for the caller to apply',
    () async {
      const eq = EqualizerSnapshot(
        settings: EqualizerSettings(enabled: true),
        profiles: [],
      );
      final backup = _backup.withEqualizer(eq);
      final report = _report(
        await _useCase(_Backups(right(backup)))(backup, BackupPart.all),
      );
      expect(report.equalizer, eq);
    },
  );

  test('parts left out are neither written nor handed back', () async {
    const eq = EqualizerSnapshot(
      settings: EqualizerSettings(enabled: true),
      profiles: [],
    );
    final backup = _backup.withEqualizer(eq);
    final backups = _Backups(right(backup));

    final report = _report(
      await _useCase(backups)(backup, {BackupPart.history}),
    );

    expect(report.settings, isNull);
    expect(report.equalizer, isNull);
    // The likes were left out: their songs are not looked for.
    expect(report.total, 0);
    expect(backups.restored?.playlists, isEmpty);
    expect(backups.restored?.parts, {BackupPart.history});
  });

  test('a file that cannot be read is reported as such', () async {
    final backups = _Backups(left(const BackupFormatFailure()));

    expect(
      await _useCase(backups).read('/f'),
      left(const BackupFormatFailure()),
    );
    expect(backups.restoredIds, isNull);
  });
}
