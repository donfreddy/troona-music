import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/entities/album.dart';

final class AlbumDetail {
  final Album album;
  final List<Album> artistAlbums;
  final List<Track> albumTracks;

  const AlbumDetail({
    required this.album,
    required this.artistAlbums,
    required this.albumTracks,
  });
}
