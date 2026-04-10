import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';

final class HomeFeed {
  final List<Track> recentlyPlayed;
  final List<Artist> yourArtists;
  final List<Album> newAlbums;
  final List<Playlist> yourPlaylists;

  const HomeFeed({
    required this.recentlyPlayed,
    required this.yourArtists,
    required this.newAlbums,
    required this.yourPlaylists,
  });
}
