import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/player/domain/entities/track_edges.dart';

/// Decodes the start and end of a song's file into a [TrackEnvelope].
abstract interface class TrackEdgeAnalyzer {
  /// [track]'s envelope. Throws [UnreadableTrack] when its file cannot be
  /// decoded (worth remembering); any other error is passing (no platform
  /// to ask, a timeout), worth trying again later.
  Future<TrackEnvelope> envelopeOf(Track track);
}

/// A file the decoder could not read.
final class UnreadableTrack implements Exception {
  const UnreadableTrack(this.reason);

  final String reason;

  @override
  String toString() => 'UnreadableTrack($reason)';
}
