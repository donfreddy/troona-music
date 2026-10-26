import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/history/data/models/listening_models.dart';
import 'package:troona/features/history/data/models/play_event_model.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';

/// Play events in the shared Isar database, capped at [maxEvents]: each
/// insert drops the oldest events beyond the cap in the same transaction.
///
/// Every event is also counted in daily totals that are never pruned (see
/// `listening_models.dart`), so weeks and months stay readable long after
/// their events are gone.
final class IsarPlayHistoryDataSource {
  final Isar _isar;
  final int maxEvents;

  IsarPlayHistoryDataSource(this._isar, {this.maxEvents = 500});

  /// The collections this data source reads and writes.
  static final schemas = [
    PlayEventModelSchema,
    ListeningDayModelSchema,
    TrackDayModelSchema,
    TrackFirstPlayModelSchema,
  ];

  Future<void> add(PlayEventModel event) async => _isar.write((isar) {
    final events = isar.playEventModels;
    event.id = events.autoIncrement();
    events.put(event);
    _count(isar, event.trackId, ListeningDay.of(event.playedAt));
    final excess = events.count() - maxEvents;
    if (excess > 0) {
      final oldest = events.where().sortByPlayedAt().findAll(limit: excess);
      events.deleteAll([for (final e in oldest) e.id]);
    }
  });

  static void _count(Isar isar, String trackId, int day) {
    final days = isar.listeningDayModels;
    days.put((days.get(day) ?? (ListeningDayModel()..id = day))..plays += 1);

    final trackDays = isar.trackDayModels;
    final key = '$day:$trackId';
    trackDays.put(
      (trackDays.get(key) ??
            (TrackDayModel()
              ..id = key
              ..day = day
              ..trackId = trackId))
        ..plays += 1,
    );

    final firstPlays = isar.trackFirstPlayModels;
    if (firstPlays.get(trackId) == null) {
      firstPlays.put(
        TrackFirstPlayModel()
          ..id = trackId
          ..day = day,
      );
    }
  }

  Future<void> addListening(int day, int ms) async => _isar.write((isar) {
    final days = isar.listeningDayModels;
    days.put(
      (days.get(day) ?? (ListeningDayModel()..id = day))..listenedMs += ms,
    );
  });

  /// Builds the daily totals from the events still stored, once: the
  /// history kept before them only has its last [maxEvents] plays.
  /// Listening time before that is unknown and stays at zero.
  Future<void> backfillDays() async => _isar.write((isar) {
    if (isar.listeningDayModels.count() > 0) return;
    for (final e in isar.playEventModels.where().sortByPlayedAt().findAll()) {
      _count(isar, e.trackId, ListeningDay.of(e.playedAt));
    }
  });

  ListeningStats listeningStats(int firstDay, int lastDay) {
    final days = _isar.listeningDayModels
        .where()
        .idBetween(firstDay, lastDay)
        .findAll();
    final trackPlays = <String, int>{};
    for (final t
        in _isar.trackDayModels
            .where()
            .dayBetween(firstDay, lastDay)
            .findAll()) {
      trackPlays[t.trackId] = (trackPlays[t.trackId] ?? 0) + t.plays;
    }
    return ListeningStats(
      plays: days.fold(0, (sum, d) => sum + d.plays),
      listened: Duration(
        milliseconds: days.fold(0, (sum, d) => sum + d.listenedMs),
      ),
      trackPlays: trackPlays,
      discoveries: _isar.trackFirstPlayModels
          .where()
          .dayBetween(firstDay, lastDay)
          .count(),
      historyStart: _isar.listeningDayModels.where().sortById().findFirst()?.id,
    );
  }

  Set<int> activeDays(int firstDay, int lastDay) => {
    for (final d
        in _isar.listeningDayModels
            .where()
            .idBetween(firstDay, lastDay)
            .and()
            .playsGreaterThan(0)
            .findAll())
      d.id,
  };

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
  /// Used by the "Hidden Gems" home section: tracks the user liked but
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
