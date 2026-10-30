import 'dart:io';
import 'dart:isolate';

import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/backup/data/backup_codec.dart';
import 'package:troona/features/backup/data/isar_backup_data_source.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/history/domain/repositories/monthly_replay_log.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

final class BackupRepositoryImpl implements BackupRepository {
  final IsarBackupDataSource _source;
  final SettingsRepository _settings;
  final MonthlyReplayLog _replayLog;

  /// Holds the export being shared; emptied once it is (see
  /// [clearExports]), since it carries the listening history.
  final Directory _exportDir;
  final DateTime Function() _now;

  BackupRepositoryImpl({
    required IsarBackupDataSource source,
    required SettingsRepository settings,
    required MonthlyReplayLog replayLog,
    required Directory exportDir,
    DateTime Function()? now,
  }) : _source = source,
       _settings = settings,
       _replayLog = replayLog,
       _exportDir = exportDir,
       _now = now ?? DateTime.now;

  @override
  Future<Either<Failure, String>> exportToFile() async {
    try {
      final settings = await _settings.loadSettings();
      return await settings.fold((f) async => left(f), (settings) async {
        final now = _now();
        final backup = _source.read(
          createdAt: now,
          settings: settings,
          replayMonth: _replayLog.lastMonth,
        );
        if (await _exportDir.exists()) {
          await _exportDir.delete(recursive: true);
        }
        await _exportDir.create(recursive: true);
        final date = now.toIso8601String().substring(0, 10);
        final file = File('${_exportDir.path}/troona-backup-$date.json');
        await file.writeAsBytes(BackupCodec.encode(backup), flush: true);
        return right(file.path);
      });
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Backup>> readFile(String path) async {
    try {
      final file = File(path);
      // Checked before reading: the file comes from anywhere.
      if (await file.length() > BackupCodec.maxBytes) {
        return left(const BackupFormatFailure('File too large'));
      }
      final bytes = await file.readAsBytes();
      // Up to 20 MB of JSON: parsed away from the UI thread.
      return right(await Isolate.run(() => BackupCodec.decode(bytes)));
    } on BackupFormatException catch (e) {
      return left(BackupFormatFailure(e.message));
    } on BackupVersionException catch (e) {
      return left(BackupTooNewFailure(e.version));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> restore(
    Backup backup,
    Map<String, String> ids,
  ) async {
    try {
      await _source.restore(backup, ids);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
    // After the commit, so a failure here must not report the restore as
    // failed: the worst outcome is one Replay playlist made twice.
    try {
      // A month handled on either phone is not made again.
      final saved = backup.replayMonth;
      final local = _replayLog.lastMonth;
      if (saved != null && (local == null || saved > local)) {
        await _replayLog.setLastMonth(saved);
      }
    } catch (e, st) {
      appLogger.w('Replay month not restored', error: e, stackTrace: st);
    }
    return right(unit);
  }

  @override
  Future<void> clearExports() async {
    try {
      if (await _exportDir.exists()) await _exportDir.delete(recursive: true);
    } catch (e, st) {
      appLogger.w('Backup export not deleted', error: e, stackTrace: st);
    }
  }
}
