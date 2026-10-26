import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/history/data/models/play_event_model.dart';

/// Play events in the shared Isar database, capped at [maxEvents]: each
/// insert drops the oldest events beyond the cap in the same transaction.
final class IsarPlayHistoryDataSource {
  final Isar _isar;
  final int maxEvents;

  IsarPlayHistoryDataSource(this._isar, {this.maxEvents = 500});

  /// The collections this data source reads and writes.
  static final schemas = [PlayEventModelSchema];

  Future<void> add(PlayEventModel event) async => _isar.write((isar) {
    final events = isar.playEventModels;
    event.id = events.autoIncrement();
    events.put(event);
    final excess = events.count() - maxEvents;
    if (excess > 0) {
      final oldest = events.where().sortByPlayedAt().findAll(limit: excess);
      events.deleteAll([for (final e in oldest) e.id]);
    }
  });

  /// Fires after every write to the play events.
  Stream<void> watch() => _isar.playEventModels.watchLazy();

  /// Distinct track ids, most recent first. Reads at most [scan] events,
  /// enough for a short list even when a few tracks are played on repeat.
  Future<List<String>> recentTrackIds({
    required int limit,
    int scan = 100,
  }) async {
    final events = _isar.playEventModels.where().sortByPlayedAtDesc().findAll(
      limit: scan,
    );
    final ids = <String>{};
    for (final e in events) {
      ids.add(e.trackId);
      if (ids.length == limit) break;
    }
    return ids.toList();
  }

  /// Returns a map of {trackId: playCount} for plays in the last [days],
  /// sorted by play count descending, limited to [limit] entries.
  ///
  /// Used by the "Your Top This Week" home section.
  Map<String, int> topTrackIds({int days = 7, int limit = 5}) {
    final since = DateTime.now().subtract(Duration(days: days));
    final events = _isar.playEventModels
        .where()
        .playedAtGreaterThan(since)
        .findAll();
    final counts = <String, int>{};
    for (final e in events) {
      counts[e.trackId] = (counts[e.trackId] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted.take(limit)) e.key: e.value};
  }

  /// Returns track IDs from [likedIds] that have not been played in the
  /// last [staleDays] days, limited to [limit].
  ///
  /// Used by the "Hidden Gems" home section — tracks the user liked but
  /// hasn't listened to recently.
  List<String> forgottenTrackIds(
    Set<String> likedIds, {
    int staleDays = 14,
    int limit = 5,
  }) {
    if (likedIds.isEmpty) return const [];
    final since = DateTime.now().subtract(Duration(days: staleDays));
    // Collect IDs of tracks played recently.
    final recentEvents = _isar.playEventModels
        .where()
        .playedAtGreaterThan(since)
        .findAll();
    final recentlyPlayed = <String>{};
    for (final e in recentEvents) {
      recentlyPlayed.add(e.trackId);
    }
    // Liked but not recently played.
    final forgotten = <String>[];
    for (final id in likedIds) {
      if (!recentlyPlayed.contains(id)) {
        forgotten.add(id);
        if (forgotten.length == limit) break;
      }
    }
    return forgotten;
  }

  /// Total number of plays recorded in the last [days] days.
  int totalPlays({int days = 7}) {
    final since = DateTime.now().subtract(Duration(days: days));
    return _isar.playEventModels.where().playedAtGreaterThan(since).count();
  }
}
