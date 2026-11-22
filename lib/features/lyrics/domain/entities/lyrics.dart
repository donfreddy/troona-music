import 'package:equatable/equatable.dart';

/// Where a song's lyrics were found.
enum LyricsSource {
  /// A file the user imported for this song.
  imported,

  /// The audio file's own tags.
  embedded,

  /// LRCLIB, when its switch is on.
  online,
}

/// One timed line. An empty [text] is a timed pause (an instrumental).
final class LyricLine extends Equatable {
  final Duration at;
  final String text;

  const LyricLine(this.at, this.text);

  bool get isPause => text.isEmpty;

  @override
  List<Object?> get props => [at, text];
}

/// A song's lyrics: timed lines, or plain text. Two types rather than a
/// flag, so a screen cannot forget the case with no times.
sealed class Lyrics extends Equatable {
  const Lyrics();

  LyricsSource get source;
}

final class SyncedLyrics extends Lyrics {
  /// Sorted by time; two lines may share one.
  final List<LyricLine> lines;

  /// The file's own `[offset:]`: positive shows the lines earlier.
  final Duration offset;

  @override
  final LyricsSource source;

  const SyncedLyrics(
    this.lines, {
    required this.source,
    this.offset = Duration.zero,
  });

  @override
  List<Object?> get props => [lines, offset, source];
}

final class PlainLyrics extends Lyrics {
  final String text;

  @override
  final LyricsSource source;

  const PlainLyrics(this.text, {required this.source});

  @override
  List<Object?> get props => [text, source];
}
