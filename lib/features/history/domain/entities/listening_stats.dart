/// What the history knows about a span of days.
final class ListeningStats {
  final int plays;
  final Duration listened;

  /// Plays per track id.
  final Map<String, int> trackPlays;

  /// Tracks played for the first time in the span.
  final int discoveries;

  /// The first day the history covers, or null when it is empty. Plays
  /// before it are unknown, so a "first play" close to it may not be one.
  final int? historyStart;

  const ListeningStats({
    required this.plays,
    required this.listened,
    required this.trackPlays,
    required this.discoveries,
    required this.historyStart,
  });

  static const empty = ListeningStats(
    plays: 0,
    listened: Duration.zero,
    trackPlays: {},
    discoveries: 0,
    historyStart: null,
  );
}
