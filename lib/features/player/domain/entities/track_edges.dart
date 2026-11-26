/// The loudness of a song's start and end, as decoded from its file: one
/// level in dBFS per window, [noData] where a window holds no sample.
final class TrackEnvelope {
  const TrackEnvelope({
    required this.duration,
    required this.window,
    required this.head,
    required this.tailFrom,
    required this.tail,
  });

  /// Below any level a sample can have: a window past the audio's end.
  static const noData = -150.0;

  /// The file's length, as its decoder reads it.
  final Duration duration;

  /// The length of each window.
  final Duration window;

  /// The levels from the start of the file.
  final List<double> head;

  /// Where [tail] starts.
  final Duration tailFrom;

  /// The levels up to the end of the file.
  final List<double> tail;
}

/// Where a song's music starts and stops, and how it ends.
final class TrackEdges {
  const TrackEdges({
    required this.musicStart,
    required this.musicEnd,
    this.fadeDown,
  });

  /// After the silence it may start with.
  final Duration musicStart;

  /// Where the music is over: before the silence it may end with, or its
  /// quiet outro (a reverb tail, a held note dying away).
  final Duration musicEnd;

  /// When the song fades out by itself: where it is down by 9 dB. The
  /// next song can come in there, without lowering this one further.
  final Duration? fadeDown;

  @override
  bool operator ==(Object other) =>
      other is TrackEdges &&
      other.musicStart == musicStart &&
      other.musicEnd == musicEnd &&
      other.fadeDown == fadeDown;

  @override
  int get hashCode => Object.hash(musicStart, musicEnd, fadeDown);

  @override
  String toString() =>
      'TrackEdges(musicStart: $musicStart, musicEnd: $musicEnd, '
      'fadeDown: $fadeDown)';
}
