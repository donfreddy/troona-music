import 'package:troona/core/error/error_handler.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/data/models/track_edges_model.dart';
import 'package:troona/features/player/data/sources/isar_track_edges_data_source.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';
import 'package:troona/features/player/domain/ports/track_edge_analyzer.dart';
import 'package:troona/features/player/domain/repositories/track_edges_repository.dart';
import 'package:troona/features/player/domain/services/edge_detector.dart';

/// Reads a song's edges from the database, or finds them in its file and
/// stores them. A file that cannot be read is remembered as such; a
/// passing failure (no platform, a timeout) stores nothing.
final class TrackEdgesRepositoryImpl implements TrackEdgesRepository {
  TrackEdgesRepositoryImpl({
    required IsarTrackEdgesDataSource store,
    required TrackEdgeAnalyzer analyzer,
    DateTime Function()? now,
  }) : _store = store,
       _analyzer = analyzer,
       _now = now ?? DateTime.now;

  final IsarTrackEdgesDataSource _store;
  final TrackEdgeAnalyzer _analyzer;
  final DateTime Function() _now;

  @override
  Future<TrackEdges?> edgesOf(Track track) async {
    final stored = _store.get(track.id);
    if (stored != null && _sameFile(stored, track)) return _edgesOf(stored);
    final row = TrackEdgesModel()
      ..id = track.id
      ..size = track.size
      ..modifiedMs = track.dateModified?.millisecondsSinceEpoch
      ..analyzedAt = _now();
    TrackEdges? edges;
    try {
      edges = EdgeDetector.detect(await _analyzer.envelopeOf(track));
      row
        ..musicStartMs = edges.musicStart.inMilliseconds
        ..musicEndMs = edges.musicEnd.inMilliseconds
        ..fadeDownMs = edges.fadeDown?.inMilliseconds;
    } on UnreadableTrack {
      // Kept with no edges.
    } catch (e, st) {
      ErrorHandler.handle(e, st);
      return null;
    }
    try {
      await _store.put(row);
    } catch (e, st) {
      // The edges still serve until the app closes.
      ErrorHandler.handle(e, st);
    }
    return edges;
  }

  static bool _sameFile(TrackEdgesModel row, Track track) =>
      row.size == track.size &&
      row.modifiedMs == track.dateModified?.millisecondsSinceEpoch;

  static TrackEdges? _edgesOf(TrackEdgesModel row) {
    final (start, end) = (row.musicStartMs, row.musicEndMs);
    if (start == null || end == null) return null;
    return TrackEdges(
      musicStart: Duration(milliseconds: start),
      musicEnd: Duration(milliseconds: end),
      fadeDown: switch (row.fadeDownMs) {
        final ms? => Duration(milliseconds: ms),
        null => null,
      },
    );
  }
}
