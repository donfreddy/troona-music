import 'package:troona/features/lyrics/data/sources/lyrics_query.dart';

/// An online source of lyrics, asked only while the user's switch is on.
abstract interface class LyricsRemoteSource {
  /// The lyrics of the song [query] describes, as LRC or plain text; null
  /// when the source has none for it. Throws [LyricsUnreachable] when it
  /// could not answer.
  Future<String?> find(LyricsQuery query);
}

/// A source gave no answer: no network, a timeout, a server down or over
/// its quota. Not a miss: nothing is remembered, the next look asks again.
final class LyricsUnreachable implements Exception {
  final String reason;

  const LyricsUnreachable(this.reason);

  @override
  String toString() => 'LyricsUnreachable: $reason';
}
