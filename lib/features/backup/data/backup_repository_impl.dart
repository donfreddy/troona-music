import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/backup/data/backup_file_name.dart';
import 'package:troona/features/backup/data/backup_files.dart';
import 'package:troona/features/backup/data/isar_backup_data_source.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';
import 'package:troona/features/equalizer/domain/entities/equalizer_snapshot.dart';
import 'package:troona/features/equalizer/domain/repositories/equalizer_repository.dart';
import 'package:troona/features/history/domain/repositories/monthly_replay_log.dart';
import 'package:troona/features/settings/domain/entities/app_settings.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

final class BackupRepositoryImpl implements BackupRepository {
  final IsarBackupDataSource _source;
  final SettingsRepository _settings;
  final MonthlyReplayLog _replayLog;

  /// Its setting and profiles go into exports; none without it.
  final EqualizerRepository? _equalizer;

  /// Holds the export being shared; emptied once it is (see
  /// [clearExports]), since it carries the listening history.
  final Directory _exportDir;
  final DateTime Function() _now;

  BackupRepositoryImpl({
    required IsarBackupDataSource source,
    required SettingsRepository settings,
    required MonthlyReplayLog replayLog,
    required Directory exportDir,
    EqualizerRepository? equalizer,
    DateTime Function()? now,
  }) : _source = source,
       _settings = settings,
       _replayLog = replayLog,
       _equalizer = equalizer,
       _exportDir = exportDir,
       _now = now ?? DateTime.now;

  @override
  Future<Either<Failure, Backup>> snapshot(Set<BackupPart> parts) async {
    try {
      AppSettings? settings;
      if (parts.contains(BackupPart.settings)) {
        final loaded = await _settings.loadSettings();
        final failure = loaded.fold<Failure?>((f) => f, (s) {
          settings = s;
          return null;
        });
        if (failure != null) return left(failure);
      }
      final backup = _source.read(
        createdAt: _now(),
        settings: settings,
        replayMonth: _replayLog.lastMonth,
        parts: parts,
      );
      return right(
        backup.withEqualizer(switch (_equalizer) {
          final eq? when parts.contains(BackupPart.equalizer) =>
            EqualizerSnapshot(
              settings: eq.loadSettings(),
              profiles: eq.loadProfiles(),
            ),
          _ => null,
        }),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, String>> exportToFile(Backup backup) async {
    try {
      if (await _exportDir.exists()) {
        await _exportDir.delete(recursive: true);
      }
      await _exportDir.create(recursive: true);
      final name = BackupFileName.of(backup.createdAt, auto: false);
      final file = File('${_exportDir.path}/$name');
      await BackupFiles.write(backup, file);
      return right(file.path);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Backup>> readFile(String path) =>
      BackupFiles.read(path);

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
