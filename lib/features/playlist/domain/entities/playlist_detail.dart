import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';

final class PlaylistDetail {
  final Playlist playlist;
  final List<Track> tracks;

  const PlaylistDetail({
    required this.playlist,
    required this.tracks,
  });
}
