import 'package:troona/features/library/domain/entities/track.dart';

final class HomeFeed {
  final List<Playlist> popularPlaylists;
  final List<Track> trendingTracks;
  const HomeFeed({required this.popularPlaylists, required this.trendingTracks});
}
