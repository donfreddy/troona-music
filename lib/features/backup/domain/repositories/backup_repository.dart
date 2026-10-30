import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';

abstract interface class BackupRepository {
  /// Writes a backup of the playlists, history and settings to a file, and
  /// returns its path.
  Future<Either<Failure, String>> exportToFile();

  /// Deletes exported files: they carry the listening history.
  Future<void> clearExports();

  /// Reads the backup file at [path]: [BackupFormatFailure] when it is not
  /// one, [BackupTooNewFailure] when a newer app made it.
  Future<Either<Failure, Backup>> readFile(String path);

  /// Merges [backup] into this phone. [ids] gives the device id of each of
  /// its songs found in the library. Settings are not applied here.
  Future<Either<Failure, Unit>> restore(Backup backup, Map<String, String> ids);
}
