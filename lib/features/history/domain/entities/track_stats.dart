/// Every song's plays, day by day, from the daily totals (never pruned):
/// what smart playlists filter and sort by.
final class TrackStats {
  /// [days] holds, per track id, its `(day, plays)` pairs in any order;
  /// days are `ListeningDay` keys.
  TrackStats(Map<String, List<(int, int)>> days)
    : _days = {
        for (final MapEntry(:key, :value) in days.entries)
          if (value.isNotEmpty) key: [...value]..sort((a, b) => a.$1 - b.$1),
      };

  static final empty = TrackStats(const {});

  final Map<String, List<(int, int)>> _days;

  /// Plays of [trackId] from [fromDay] to [toDay], both included.
  int playsBetween(String trackId, int fromDay, int toDay) {
    var sum = 0;
    for (final (day, plays) in _days[trackId] ?? const <(int, int)>[]) {
      if (day > toDay) break;
      if (day >= fromDay) sum += plays;
    }
    return sum;
  }

  /// All-time plays of [trackId]; 0 if never played.
  int total(String trackId) {
    var sum = 0;
    for (final (_, plays) in _days[trackId] ?? const <(int, int)>[]) {
      sum += plays;
    }
    return sum;
  }

  /// The last day [trackId] was played; null if never.
  int? lastDay(String trackId) => _days[trackId]?.last.$1;
}
