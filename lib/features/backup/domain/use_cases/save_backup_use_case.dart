import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_folder_repository.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';

/// Writes a backup of the [parts] chosen to the folder, by hand: it is
/// never deleted to make room.
final class SaveBackupUseCase {
  final BackupRepository _backups;
  final BackupFolderRepository _folder;

  const SaveBackupUseCase(this._backups, this._folder);

  Future<Either<Failure, StoredBackup>> call(Set<BackupPart> parts) async {
    final backup = await _backups.snapshot(parts);
    return backup.fold(
      (f) async => left(f),
      (b) => _folder.save(b, auto: false),
    );
  }
}
