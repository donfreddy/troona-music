import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';

final class ArtistDetail {
  final Artist artist;
  final List<Track> topTracks;
  final List<Album> albums;

  const ArtistDetail({
    required this.artist,
    required this.topTracks,
    required this.albums,
  });
}
