/// One counted listen of a track (see `PlayCounter` for what counts).
final class PlayEvent {
  final String trackId;
  final DateTime playedAt;

  const PlayEvent({required this.trackId, required this.playedAt});
}
