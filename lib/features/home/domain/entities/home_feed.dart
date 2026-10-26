import 'package:troona/features/home/domain/entities/track_play_count.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';

final class HomeFeed {
  final List<Track> recentlyPlayed;
  final List<Artist> yourArtists;
  final List<Album> newAlbums;
  final List<Playlist> yourPlaylists;

  // ── Enriched sections (stats-driven) ──────────────────────────────────────

  /// Top played tracks this week, ordered by play count descending.
  final List<TrackPlayCount> topWeekly;

  /// Liked tracks the user hasn't listened to in a while: "redécouvrez".
  final List<Track> hiddenGems;

  /// Number of liked tracks (badge on the Quick Access chip).
  final int likesCount;

  /// Total plays recorded this week (displayed in stats).
  final int weeklyPlayCount;

  const HomeFeed({
    required this.recentlyPlayed,
    required this.yourArtists,
    required this.newAlbums,
    required this.yourPlaylists,
    this.topWeekly = const [],
    this.hiddenGems = const [],
    this.likesCount = 0,
    this.weeklyPlayCount = 0,
  });

  /// True when the user has never listened to anything: triggers Cold Start.
  bool get isColdStart =>
      recentlyPlayed.isEmpty && topWeekly.isEmpty && weeklyPlayCount == 0;
}
