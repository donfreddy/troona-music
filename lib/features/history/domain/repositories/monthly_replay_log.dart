/// Remembers the last month a Replay was handled for, so each month is
/// handled once, even when the user deletes its playlist.
abstract interface class MonthlyReplayLog {
  /// As `year * 12 + month - 1`; null before the first Replay.
  int? get lastMonth;

  Future<void> setLastMonth(int month);
}
