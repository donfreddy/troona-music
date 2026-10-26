import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';

/// Builds albums and artists from tracks, keyed by the MediaStore ids the
/// detail pages query with. Grouping by name merged distinct albums that
/// share a title ("Greatest Hits") and linked to only one of them.
abstract final class LibraryGrouping {
  LibraryGrouping._();

  static List<Album> albumsOf(List<Track> tracks) {
    final groups = <int, List<Track>>{};
    for (final t in tracks) {
      groups.putIfAbsent(t.albumId, () => []).add(t);
    }
    return [
      for (final group in groups.values)
        Album(
          id: group.first.albumId.toString(),
          name: group.first.album,
          artist: group.first.artist,
          artistId: group.first.artistId,
          trackCount: group.length,
          artworkPath: _firstArtwork(group),
        ),
    ];
  }

  static List<Artist> artistsOf(List<Track> tracks) {
    final groups = <int, List<Track>>{};
    for (final t in tracks) {
      groups.putIfAbsent(t.artistId, () => []).add(t);
    }
    return [
      for (final group in groups.values)
        Artist(
          id: group.first.artistId.toString(),
          name: group.first.artist,
          albumCount: {for (final t in group) t.albumId}.length,
          trackCount: group.length,
          artworkPath: _firstArtwork(group),
        ),
    ];
  }

  /// The first cover found in the group: the first track may have none.
  static String? _firstArtwork(List<Track> group) {
    for (final t in group) {
      if (t.artworkPath != null) return t.artworkPath;
    }
    return null;
  }
}
