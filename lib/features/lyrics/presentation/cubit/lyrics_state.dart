import 'package:equatable/equatable.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';

/// The lyrics of the song playing, as Now Playing shows them.
sealed class LyricsState extends Equatable {
  const LyricsState();

  /// The song these lyrics are about; null when idle.
  String? get trackId => null;
}

/// Not shown, or nothing playing: nothing read.
final class LyricsIdle extends LyricsState {
  const LyricsIdle();

  @override
  List<Object?> get props => const [];
}

final class LyricsLoading extends LyricsState {
  @override
  final String trackId;

  const LyricsLoading(this.trackId);

  @override
  List<Object?> get props => [trackId];
}

final class LyricsShown extends LyricsState {
  @override
  final String trackId;
  final Lyrics lyrics;

  /// The user's correction for this song: positive shows the lines earlier.
  final Duration offset;

  const LyricsShown(this.trackId, this.lyrics, {this.offset = Duration.zero});

  LyricsShown withOffset(Duration offset) =>
      LyricsShown(trackId, lyrics, offset: offset);

  @override
  List<Object?> get props => [trackId, lyrics, offset];
}

/// None to show for the song.
final class LyricsNone extends LyricsState {
  @override
  final String trackId;

  /// Whether the online search is on: the screen offers to search again,
  /// else to turn it on.
  final bool onlineEnabled;

  /// A source could not be reached: worth trying again later.
  final bool unreachable;

  const LyricsNone(
    this.trackId, {
    required this.onlineEnabled,
    this.unreachable = false,
  });

  @override
  List<Object?> get props => [trackId, onlineEnabled, unreachable];
}
