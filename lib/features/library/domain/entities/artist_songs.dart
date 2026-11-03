import 'package:troona/features/library/domain/entities/track.dart';

/// The songs of an artist page, most played first.
final class ArtistSongs {
  final List<Track> tracks;

  /// Whether any of [tracks] was ever played, so the order means
  /// something: the page then calls them Popular.
  final bool byPlays;

  const ArtistSongs({this.tracks = const [], this.byPlays = false});

  /// [tracks] by all-time [plays], most played first; songs never played
  /// come after, by title.
  factory ArtistSongs.ranked(List<Track> tracks, Map<String, int> plays) {
    int playsOf(Track t) => plays[t.id] ?? 0;
    final ranked = List.of(tracks)
      ..sort((a, b) {
        final byPlays = playsOf(b).compareTo(playsOf(a));
        if (byPlays != 0) return byPlays;
        final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
      });
    return ArtistSongs(
      tracks: ranked,
      byPlays: tracks.any((t) => playsOf(t) > 0),
    );
  }
}
