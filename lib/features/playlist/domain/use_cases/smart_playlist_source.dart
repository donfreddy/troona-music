import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/track_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/smart_rules.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:troona/features/playlist/domain/services/smart_playlist.dart';

/// What smart playlists are worked out from, read once: the library, every
/// song's plays and the liked songs. The editor reads it once and counts
/// as the rules change; a playlist page reads it on each load.
final class SmartPlaylistInputs {
  final List<Track> library;
  final TrackStats stats;
  final Set<String> liked;
  final int today;

  const SmartPlaylistInputs({
    required this.library,
    required this.stats,
    required this.liked,
    required this.today,
  });

  /// How many songs [evaluate] would return, without sorting them.
  int count(SmartRules rules) => SmartPlaylist.count(
    rules,
    library,
    stats: stats,
    liked: liked,
    today: today,
  );

  List<Track> evaluate(SmartRules rules, {int seed = 0}) =>
      SmartPlaylist.evaluate(
        rules,
        library,
        stats: stats,
        liked: liked,
        today: today,
        seed: seed,
      );
}

/// Reads [SmartPlaylistInputs]: all three are needed. A history or liked
/// songs read as none would let in every song for "never played" or "not
/// liked", and a playlist saved from that would keep them.
final class SmartPlaylistSource {
  final LibraryRepository _library;
  final PlayHistoryRepository _history;
  final PlaylistRepository _playlists;
  final DateTime Function() _now;

  SmartPlaylistSource({
    required LibraryRepository library,
    required PlayHistoryRepository history,
    required PlaylistRepository playlists,
    DateTime Function()? now,
  }) : _library = library,
       _history = history,
       _playlists = playlists,
       _now = now ?? DateTime.now;

  Future<Either<Failure, SmartPlaylistInputs>> read() async {
    final library = await _library.getTracks();
    final stats = await _history.trackStats();
    final likes = await _playlists.getPlaylistById(Playlist.likesId);
    return library.flatMap(
      (tracks) => stats.flatMap(
        (stats) => likes.map(
          (likes) => SmartPlaylistInputs(
            library: tracks,
            stats: stats,
            liked: likes.trackIds.toSet(),
            today: ListeningDay.of(_now()),
          ),
        ),
      ),
    );
  }
}
