import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';

final class ExportBackupUseCase {
  final BackupRepository _repo;
  const ExportBackupUseCase(this._repo);

  /// The path of a file holding the [parts] chosen. Call [discard] once it
  /// is shared.
  Future<Either<Failure, String>> call(Set<BackupPart> parts) async {
    final backup = await _repo.snapshot(parts);
    return backup.fold((f) async => left(f), _repo.exportToFile);
  }

  Future<void> discard() => _repo.clearExports();
}
