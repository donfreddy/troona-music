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
}
