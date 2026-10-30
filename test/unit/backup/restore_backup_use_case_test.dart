import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/backup/domain/use_cases/restore_backup_use_case.dart';
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
  playlists: const [],
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
  Map<String, String>? restoredIds;

  @override
  Future<Either<Failure, Backup>> readFile(String path) async => file;

  @override
  Future<Either<Failure, Unit>> restore(
    Backup backup,
    Map<String, String> ids,
  ) async {
    restoredIds = ids;
    return right(unit);
  }

  @override
  Future<Either<Failure, String>> exportToFile() => throw UnimplementedError();

  @override
  Future<void> clearExports() async {}
}

final class _Library extends Fake implements LibraryRepository {
  @override
  Future<Either<Failure, List<Track>>> getTracks() async =>
      right([testTrack('a', durationMs: 200000)]);
}

void main() {
  test('restores the songs found and reports the others', () async {
    final backups = _Backups(right(_backup));

    final report = await RestoreBackupUseCase(backups, _Library())('/f');

    expect(backups.restoredIds, {'k1': 'a'});
    final value = report.getOrElse(() => throw StateError('failed'));
    expect(value.found, 1);
    expect(value.total, 2);
    expect(value.missing.single.fileName, 'gone.mp3');
    expect(value.settings.fetchOnlineMetadata, isTrue);
  });

  test('an unreadable file restores nothing', () async {
    final backups = _Backups(left(const BackupFormatFailure()));

    final report = await RestoreBackupUseCase(backups, _Library())('/f');

    expect(report, left(const BackupFormatFailure()));
    expect(backups.restoredIds, isNull);
  });
}
