import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_preferences.dart';
import 'package:troona/features/backup/domain/repositories/backup_preferences_repository.dart';

/// [BackupPreferencesRepository] in [SharedPreferences]. A value that
/// cannot be read reads as the default.
final class PrefsBackupPreferencesRepository
    implements BackupPreferencesRepository {
  final SharedPreferences _prefs;

  static const partsKey = 'backup.parts';
  static const autoKey = 'backup.auto';
  static const frequencyKey = 'backup.frequency';
  static const lastAutoAtKey = 'backup.auto.lastAt';
  static const lastAutoFingerprintKey = 'backup.auto.lastFingerprint';

  const PrefsBackupPreferencesRepository(this._prefs);

  @override
  BackupPreferences load() {
    final names = _prefs.getStringList(partsKey);
    final parts = {
      for (final p in BackupPart.values)
        if (names == null || names.contains(p.name)) p,
    };
    final frequency = _prefs.getString(frequencyKey);
    return BackupPreferences(
      // Never empty: a backup of nothing helps no one.
      parts: parts.isEmpty ? BackupPart.all : parts,
      auto: _prefs.getBool(autoKey) ?? false,
      frequency: BackupFrequency.values.firstWhere(
        (f) => f.name == frequency,
        orElse: () => BackupFrequency.weekly,
      ),
    );
  }

  @override
  Future<void> save(BackupPreferences preferences) async {
    await _prefs.setStringList(partsKey, [
      for (final p in BackupPart.values)
        if (preferences.parts.contains(p)) p.name,
    ]);
    await _prefs.setBool(autoKey, preferences.auto);
    await _prefs.setString(frequencyKey, preferences.frequency.name);
  }

  @override
  AutoBackupMark? get lastAuto {
    final at = _prefs.getInt(lastAutoAtKey);
    final fingerprint = _prefs.getString(lastAutoFingerprintKey);
    if (at == null || fingerprint == null) return null;
    return AutoBackupMark(
      at: DateTime.fromMillisecondsSinceEpoch(at),
      fingerprint: fingerprint,
    );
  }

  @override
  Future<void> setLastAuto(AutoBackupMark mark) async {
    await _prefs.setInt(lastAutoAtKey, mark.at.millisecondsSinceEpoch);
    await _prefs.setString(lastAutoFingerprintKey, mark.fingerprint);
  }
}
