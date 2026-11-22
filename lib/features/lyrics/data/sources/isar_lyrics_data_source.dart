import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/lyrics/data/models/track_lyrics_model.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';

/// Lyrics in the shared Isar database, one row per song looked at.
///
/// A row with no [TrackLyricsModel.raw] is the memory that nothing was
/// found. Imported lyrics are the user's: nothing found online replaces
/// them, and clearing the online info keeps them.
final class IsarLyricsDataSource {
  final Isar _isar;

  IsarLyricsDataSource(this._isar);

  /// The collections this data source reads and writes.
  static final schemas = [TrackLyricsModelSchema];

  static final _imported = LyricsSource.imported.name;
  static final _online = LyricsSource.online.name;

  TrackLyricsModel? get(String trackId) => _isar.trackLyricsModels.get(trackId);

  /// [raw] imported for the song, over whatever it had; its timings are
  /// new, so the correction starts again from zero.
  Future<void> putImported(String trackId, String raw, DateTime at) async =>
      _isar.write(
        (isar) => isar.trackLyricsModels.put(
          TrackLyricsModel()
            ..id = trackId
            ..raw = raw
            ..source = _imported
            ..checkedAt = at,
        ),
      );

  /// What the online sources answered: [raw], or null when they had
  /// nothing. Lyrics imported meanwhile are kept: the answer is dropped.
  /// The correction stays, a search again often bringing the same lyrics.
  Future<void> putOnline(String trackId, String? raw, DateTime at) async =>
      _isar.write((isar) {
        final rows = isar.trackLyricsModels;
        final old = rows.get(trackId);
        if (old?.source == _imported) return;
        rows.put(
          TrackLyricsModel()
            ..id = trackId
            ..raw = raw
            ..source = raw == null ? null : _online
            ..offsetMs = old?.offsetMs ?? 0
            ..checkedAt = at,
        );
      });

  /// Marks a look done at [at] on the song's row, its lyrics kept.
  Future<void> touch(String trackId, DateTime at) async => _isar.write((isar) {
    final rows = isar.trackLyricsModels;
    final old = rows.get(trackId);
    if (old != null) rows.put(old..checkedAt = at);
  });

  /// Sets the song's correction; false when it has no lyrics to correct.
  Future<bool> setOffset(String trackId, int ms) async => _isar.write((isar) {
    final rows = isar.trackLyricsModels;
    final old = rows.get(trackId);
    if (old?.raw == null) return false;
    rows.put(old!..offsetMs = ms);
    return true;
  });

  /// Forgets the song's lyrics and remembers, from [at], that it has none.
  Future<void> forget(String trackId, DateTime at) async => _isar.write(
    (isar) => isar.trackLyricsModels.put(
      TrackLyricsModel()
        ..id = trackId
        ..checkedAt = at,
    ),
  );

  /// Removes every row but the imported lyrics.
  Future<void> clearOnline() async => _isar.write((isar) {
    final rows = isar.trackLyricsModels;
    final ids = [
      for (final row in rows.where().findAll())
        if (row.source != _imported) row.id,
    ];
    rows.deleteAll(ids);
  });

  /// Every imported lyrics, for a backup.
  List<TrackLyricsModel> imported() =>
      _isar.trackLyricsModels.where().sourceEqualTo(_imported).findAll();
}
