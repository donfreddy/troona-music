import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/artist_albums.dart';
import 'package:troona/features/library/domain/entities/track.dart';

final class ArtistDetail {
  final Artist artist;
  final List<Track> topTracks;
  final ArtistAlbums albums;

  const ArtistDetail({
    required this.artist,
    required this.topTracks,
    required this.albums,
  });

  /// Every album with a song of theirs, their own first.
  List<Album> get allAlbums => albums.all;
}
