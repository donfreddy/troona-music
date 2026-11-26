import 'package:isar_plus/isar_plus.dart';
import 'package:troona/features/player/data/models/track_edges_model.dart';

/// Songs' edges in the shared Isar database, one row per song analysed.
final class IsarTrackEdgesDataSource {
  final Isar _isar;

  IsarTrackEdgesDataSource(this._isar);

  /// The collections this data source reads and writes.
  static final schemas = [TrackEdgesModelSchema];

  TrackEdgesModel? get(String trackId) => _isar.trackEdgesModels.get(trackId);

  Future<void> put(TrackEdgesModel row) async =>
      _isar.write((isar) => isar.trackEdgesModels.put(row));
}
