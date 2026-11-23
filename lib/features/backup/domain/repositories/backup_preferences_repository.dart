import 'package:troona/features/backup/domain/entities/backup_preferences.dart';

abstract interface class BackupPreferencesRepository {
  BackupPreferences load();
  Future<void> save(BackupPreferences preferences);

  AutoBackupMark? get lastAuto;
  Future<void> setLastAuto(AutoBackupMark mark);

  /// When the last automatic backup failed; null once one succeeds.
  DateTime? get lastFailure;
  Future<void> setLastFailure(DateTime? at);
}
