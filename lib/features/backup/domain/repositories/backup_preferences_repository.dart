import 'package:troona/features/backup/domain/entities/backup_preferences.dart';

abstract interface class BackupPreferencesRepository {
  BackupPreferences load();
  Future<void> save(BackupPreferences preferences);

  AutoBackupMark? get lastAuto;
  Future<void> setLastAuto(AutoBackupMark mark);
}
