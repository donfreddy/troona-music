import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';

/// Where songs' music starts and stops, found once per file.
abstract interface class TrackEdgesRepository {
  /// [track]'s edges: stored, or found in its file now (several seconds)
  /// and stored. Null when its file cannot be read, or could not be
  /// analysed this time.
  Future<TrackEdges?> edgesOf(Track track);
}
