import 'package:equatable/equatable.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';

/// What a look for a song's lyrics came back with.
sealed class LyricsLookup extends Equatable {
  const LyricsLookup();
}

/// Lyrics to show, with the user's correction for this song (positive
/// shows the lines earlier), apart from the file's own `[offset:]`.
final class LyricsFound extends LyricsLookup {
  final Lyrics lyrics;
  final Duration offset;

  const LyricsFound(this.lyrics, {this.offset = Duration.zero});

  @override
  List<Object?> get props => [lyrics, offset];
}

/// None to show.
final class LyricsMissing extends LyricsLookup {
  /// Whether the online search is on: off, the screen offers to turn it
  /// on; on, to search again.
  final bool onlineEnabled;

  /// Whether a source could not be reached (no network, a server down):
  /// nothing was remembered, the next look asks again.
  final bool unreachable;

  const LyricsMissing({required this.onlineEnabled, this.unreachable = false});

  @override
  List<Object?> get props => [onlineEnabled, unreachable];
}
