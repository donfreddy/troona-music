import 'package:shared_preferences/shared_preferences.dart';
import 'package:troona/features/history/domain/repositories/monthly_replay_log.dart';

final class SharedPrefsMonthlyReplayLog implements MonthlyReplayLog {
  static const _key = 'monthly_replay_last_month_v1';

  final SharedPreferences _prefs;

  const SharedPrefsMonthlyReplayLog(this._prefs);

  @override
  int? get lastMonth => _prefs.getInt(_key);

  @override
  Future<void> setLastMonth(int month) => _prefs.setInt(_key, month);
}
