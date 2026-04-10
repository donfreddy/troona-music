import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';

final class SearchResult {
  final List<Track> tracks;
  final List<Artist> artists;
  final List<Album> albums;

  const SearchResult({
    required this.tracks,
    required this.artists,
    required this.albums,
  });

  bool get isEmpty => tracks.isEmpty && artists.isEmpty && albums.isEmpty;

  factory SearchResult.empty() => const SearchResult(
    tracks: [],
    artists: [],
    albums: [],
  );
}
