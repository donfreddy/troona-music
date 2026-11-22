import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics_lookup.dart';

/// A song's lyrics: imported by the user first, then found online (opt-in).
abstract interface class LyricsRepository {
  /// The largest correction kept, either way.
  static const maxOffset = Duration(seconds: 10);

  /// The lyrics to show for [track]. What was not found online is
  /// remembered for a while; [searchAgain] asks anyway. Never throws.
  Future<LyricsLookup> lyricsFor(Track track, {bool searchAgain = false});

  /// Keeps the lyrics file [bytes] for [track], over any it had, and
  /// returns them. [LyricsFormatFailure] when the file holds none.
  Future<Either<Failure, Lyrics>> import(Track track, List<int> bytes);

  /// The user's correction for this song's lyrics, within [maxOffset].
  Future<Either<Failure, Unit>> setOffset(String trackId, Duration offset);

  /// Forgets the song's lyrics, and remembers that it has none: lyrics
  /// found online come back only when searched for again.
  Future<Either<Failure, Unit>> delete(String trackId);

  /// Forgets every lyrics found online, and what was not found; the
  /// imported ones stay.
  Future<void> clearOnline();
}
