import 'package:equatable/equatable.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/backup/domain/entities/backup_preferences.dart';
import 'package:troona/features/backup/domain/entities/stored_backup.dart';
import 'package:troona/features/backup/domain/repositories/backup_folder_repository.dart';
import 'package:troona/features/backup/domain/repositories/backup_preferences_repository.dart';
import 'package:troona/features/backup/domain/repositories/backup_repository.dart';

sealed class AutoBackupOutcome extends Equatable {
  const AutoBackupOutcome();

  @override
  List<Object?> get props => [];
}

/// Turned off, or not due yet.
final class AutoBackupSkipped extends AutoBackupOutcome {
  const AutoBackupSkipped();
}

/// Due, but no folder can be reached: none chosen, or its access is gone.
final class AutoBackupNoFolder extends AutoBackupOutcome {
  final BackupFolderState folder;
  const AutoBackupNoFolder(this.folder);

  @override
  List<Object?> get props => [folder];
}

/// Nothing changed since the last automatic backup, which is still there.
final class AutoBackupUnchanged extends AutoBackupOutcome {
  const AutoBackupUnchanged();
}

final class AutoBackupSaved extends AutoBackupOutcome {
  final StoredBackup backup;
  const AutoBackupSaved(this.backup);

  @override
  List<Object?> get props => [backup];
}

/// Tried again on the next check: nothing was marked as done.
final class AutoBackupFailed extends AutoBackupOutcome {
  final Failure failure;
  const AutoBackupFailed(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Writes an automatic backup to the folder when one is due, and keeps the
/// last [keep] of them. Backups made by hand are never deleted.
///
/// Run when the app starts or comes back: no background task, which
/// Android would run late or not at all, and the app is used often enough
/// for a daily or weekly backup.
final class RunAutoBackupUseCase {
  final BackupRepository _backups;
  final BackupFolderRepository _folder;
  final BackupPreferencesRepository _preferences;
  final DateTime Function() _now;

  static const keep = 5;

  RunAutoBackupUseCase({
    required BackupRepository backups,
    required BackupFolderRepository folder,
    required BackupPreferencesRepository preferences,
    DateTime Function()? now,
  }) : _backups = backups,
       _folder = folder,
       _preferences = preferences,
       _now = now ?? DateTime.now;

  Future<AutoBackupOutcome> call() async {
    final preferences = _preferences.load();
    final now = _now();
    if (!preferences.auto ||
        !isDue(_preferences.lastAuto, preferences.frequency, now)) {
      return const AutoBackupSkipped();
    }
    final folder = await _folder.state();
    if (folder is! BackupFolderReady) return AutoBackupNoFolder(folder);

    final snapshot = await _backups.snapshot(preferences.parts);
    return snapshot.fold((f) async => AutoBackupFailed(f), (backup) async {
      final fingerprint = await _backups.fingerprint(backup);
      final listed = await _folder.list();
      return listed.fold((f) async => AutoBackupFailed(f), (stored) async {
        final autos = [
          for (final b in stored)
            if (b.auto) b,
        ];
        final mark = AutoBackupMark(at: now, fingerprint: fingerprint);
        // The same data as last time, and that backup is still there (the
        // user may have deleted it): nothing to write.
        if (_preferences.lastAuto?.fingerprint == fingerprint &&
            autos.isNotEmpty) {
          await _preferences.setLastAuto(mark);
          return const AutoBackupUnchanged();
        }
        final saved = await _folder.save(backup, auto: true);
        return saved.fold((f) async => AutoBackupFailed(f), (written) async {
          await _preferences.setLastAuto(mark);
          // Oldest last: the list is newest first, and the new one is not
          // in it yet.
          for (final old in autos.skip(keep - 1)) {
            await _folder.delete(old);
          }
          return AutoBackupSaved(written);
        });
      });
    });
  }

  /// Due once a calendar day (or seven) has passed since [last], counted
  /// in local days: a backup at 21:00 is followed by one the next morning.
  /// A [last] in the future (a clock set back since) is due at once, or no
  /// backup would come until that date.
  static bool isDue(
    AutoBackupMark? last,
    BackupFrequency frequency,
    DateTime now,
  ) {
    if (last == null) return true;
    final days = _day(now) - _day(last.at);
    if (days < 0) return true;
    return days >=
        switch (frequency) {
          BackupFrequency.daily => 1,
          BackupFrequency.weekly => 7,
        };
  }

  /// Local calendar days since the epoch: hours would make a day after a
  /// change of time 23 or 25 hours long.
  static int _day(DateTime t) {
    final local = t.toLocal();
    return DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }
}
