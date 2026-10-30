import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';

final class ExportBackupUseCase {
  final BackupRepository _repo;
  const ExportBackupUseCase(this._repo);

  /// The path of the backup file written. Call [discard] once it is shared.
  Future<Either<Failure, String>> call() => _repo.exportToFile();

  Future<void> discard() => _repo.clearExports();
}
