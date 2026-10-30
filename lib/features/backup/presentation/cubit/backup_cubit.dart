import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/use_cases/export_backup_use_case.dart';
import 'package:troona/features/backup/domain/use_cases/restore_backup_use_case.dart';

/// Whether an export or a restore is running: one at a time.
final class BackupCubit extends Cubit<bool> {
  final ExportBackupUseCase _export;
  final RestoreBackupUseCase _restore;

  BackupCubit({
    required ExportBackupUseCase export,
    required RestoreBackupUseCase restore,
  }) : _export = export,
       _restore = restore,
       super(false);

  /// Writes a backup and hands its file to [share]. The file is deleted
  /// afterwards, shared or not: it carries the listening history.
  Future<Either<Failure, Unit>> export(
    Future<void> Function(String path) share,
  ) => _busy(() async {
    final written = await _export();
    try {
      return await written.fold((f) async => left(f), (path) async {
        await share(path);
        return right(unit);
      });
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    } finally {
      await _export.discard();
    }
  });

  Future<Either<Failure, RestoreReport>> restore(String path) =>
      _busy(() => _restore(path));

  /// The settings page disables both buttons while busy; a second call
  /// would still be refused here.
  Future<T> _busy<T>(Future<T> Function() run) async {
    if (state) throw StateError('A backup task is already running');
    emit(true);
    try {
      return await run();
    } finally {
      if (!isClosed) emit(false);
    }
  }
}
