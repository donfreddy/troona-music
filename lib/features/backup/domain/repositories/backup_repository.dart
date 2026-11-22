import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';

abstract interface class BackupRepository {
  /// Reads the [parts] of this phone's data into a backup: playlists,
  /// likes, history, settings, equalizer.
  Future<Either<Failure, Backup>> snapshot(Set<BackupPart> parts);

  /// Writes [backup] to a file to share, and returns its path.
  Future<Either<Failure, String>> exportToFile(Backup backup);

  /// Deletes exported files: they carry the listening history.
  Future<void> clearExports();

  /// Reads the backup file at [path]: [BackupFormatFailure] when it is not
  /// one, [BackupTooNewFailure] when a newer app made it.
  Future<Either<Failure, Backup>> readFile(String path);

  /// Merges [backup] into this phone, every part it holds (narrow it first
  /// with [Backup.only]). [ids] gives the device id of each of its songs
  /// found in the library. Settings and the equalizer are not applied here.
  Future<Either<Failure, Unit>> restore(Backup backup, Map<String, String> ids);
}
