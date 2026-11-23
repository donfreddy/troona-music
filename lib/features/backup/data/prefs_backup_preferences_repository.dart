import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/backup/domain/entities/backup.dart';
import 'package:troona/features/backup/domain/entities/backup_preferences.dart';
import 'package:troona/features/backup/domain/repositories/backup_preferences_repository.dart';

/// [BackupPreferencesRepository] in [SharedPreferences]. A value that
/// cannot be read reads as the default.
final class PrefsBackupPreferencesRepository
    implements BackupPreferencesRepository {
  final SharedPreferences _prefs;

  /// The parts left out, not those kept: a part a later version adds is in
  /// every backup until the user leaves it out.
  static const partsLeftOutKey = 'backup.partsLeftOut';
  static const autoKey = 'backup.auto';
  static const frequencyKey = 'backup.frequency';
  static const lastAutoAtKey = 'backup.auto.lastAt';
  static const lastAutoFingerprintKey = 'backup.auto.lastFingerprint';
  static const lastAutoNameKey = 'backup.auto.lastName';
  static const lastFailureKey = 'backup.auto.lastFailure';

  const PrefsBackupPreferencesRepository(this._prefs);

  @override
  BackupPreferences load() {
    final leftOut = _prefs.getStringList(partsLeftOutKey) ?? const [];
    final parts = {
      for (final p in BackupPart.values)
        if (!leftOut.contains(p.name)) p,
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
    await _prefs.setStringList(partsLeftOutKey, [
      for (final p in BackupPart.values)
        if (!preferences.parts.contains(p)) p.name,
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
      name: _prefs.getString(lastAutoNameKey),
    );
  }

  @override
  Future<void> setLastAuto(AutoBackupMark mark) async {
    await _prefs.setInt(lastAutoAtKey, mark.at.millisecondsSinceEpoch);
    await _prefs.setString(lastAutoFingerprintKey, mark.fingerprint);
    if (mark.name case final name?) {
      await _prefs.setString(lastAutoNameKey, name);
    } else {
      await _prefs.remove(lastAutoNameKey);
    }
  }

  @override
  DateTime? get lastFailure => switch (_prefs.getInt(lastFailureKey)) {
    final ms? => DateTime.fromMillisecondsSinceEpoch(ms),
    null => null,
  };

  @override
  Future<void> setLastFailure(DateTime? at) async {
    if (at == null) {
      await _prefs.remove(lastFailureKey);
    } else {
      await _prefs.setInt(lastFailureKey, at.millisecondsSinceEpoch);
    }
  }
}
