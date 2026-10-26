import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/whats_new/domain/repositories/whats_new_repository.dart';

final class SharedPrefsWhatsNewRepository implements WhatsNewRepository {
  static const _key = 'whats_new_last_seen_version_v1';

  final SharedPreferences _prefs;

  const SharedPrefsWhatsNewRepository(this._prefs);

  @override
  String? get lastSeenVersion => _prefs.getString(_key);

  @override
  Future<void> setLastSeenVersion(String version) =>
      _prefs.setString(_key, version);
}
