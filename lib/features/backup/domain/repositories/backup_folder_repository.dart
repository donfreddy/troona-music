import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_summary.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';

/// The folder the user chose for backups, and the backups in it.
///
/// Calls that reach the folder fail with [BackupFolderLostFailure] once
/// this app can no longer reach it.
abstract interface class BackupFolderRepository {
  Future<BackupFolderState> state();

  /// Asks the user for a folder. Null when they cancel; the folder chosen
  /// before stays.
  Future<Either<Failure, BackupFolder?>> pick();

  /// The backups in the folder, newest first. Other files are left out.
  Future<Either<Failure, List<StoredBackup>>> list();

  /// Writes [backup] to a new file in the folder.
  Future<Either<Failure, StoredBackup>> save(
    Backup backup, {
    required bool auto,
  });

  Future<Either<Failure, Backup>> read(StoredBackup stored);

  /// What [stored] holds, when known without reading it again: counted when
  /// it was written or last read on this phone.
  BackupSummary? summaryOf(StoredBackup stored);

  /// A copy of [stored] in a local file, to share; deleted with the other
  /// exports.
  Future<Either<Failure, String>> copyToShare(StoredBackup stored);

  Future<Either<Failure, Unit>> delete(StoredBackup stored);
}
