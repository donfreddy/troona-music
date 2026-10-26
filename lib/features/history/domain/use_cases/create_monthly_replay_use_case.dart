import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/monthly_replay_log.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';
import 'package:troona/features/playlist/domain/repositories/playlist_repository.dart';

/// Saves last month's most played songs as a normal playlist, the first
/// time the app runs in a new month. The app may not run on the 1st, so the
/// check is "a month not handled yet", not a date.
final class CreateMonthlyReplayUseCase {
  final PlayHistoryRepository _history;
  final GetTracksByIdsUseCase _getTracksByIds;
  final PlaylistRepository _playlists;
  final MonthlyReplayLog _log;

  const CreateMonthlyReplayUseCase({
    required PlayHistoryRepository history,
    required GetTracksByIdsUseCase getTracksByIds,
    required PlaylistRepository playlists,
    required MonthlyReplayLog log,
  }) : _history = history,
       _getTracksByIds = getTracksByIds,
       _playlists = playlists,
       _log = log;

  static const maxTracks = 25;

  /// Fewer songs than this make a poor playlist: the month is skipped.
  static const minTracks = 5;

  /// The playlist created, or null when last month was already handled or
  /// had too few songs. [name] titles it from the month it covers.
  Future<Either<Failure, Playlist?>> call({
    required DateTime now,
    required String Function(DateTime month) name,
  }) async {
    final month = DateTime(now.year, now.month - 1);
    final key = month.year * 12 + month.month - 1;
    final last = _log.lastMonth;
    if (last != null && last >= key) return right(null);

    final stats = await _history.listeningStats(
      firstDay: ListeningDay.of(month),
      lastDay: ListeningDay.of(DateTime(month.year, month.month + 1, 0)),
    );
    return stats.fold(left, (stats) async {
      final ranked = stats.trackPlays.entries.toList()
        ..sort((a, b) {
          final byPlays = b.value.compareTo(a.value);
          return byPlays != 0 ? byPlays : a.key.compareTo(b.key);
        });
      // Removed songs are skipped, so ask for all of them, not the top 25.
      final tracksResult = await _getTracksByIds([
        for (final e in ranked) e.key,
      ]);
      if (tracksResult.isLeft()) {
        return tracksResult.map((_) => null);
      }
      final tracks = tracksResult
          .getOrElse(() => const <Track>[])
          .take(maxTracks)
          .toList();

      if (tracks.length < minTracks) {
        await _log.setLastMonth(key);
        return right(null);
      }
      return _save(name(month), tracks, key);
    });
  }

  Future<Either<Failure, Playlist?>> _save(
    String title,
    List<Track> tracks,
    int key,
  ) async {
    final created = await _playlists.createPlaylist(title: title);
    return created.fold(left, (playlist) async {
      final filled = Playlist(
        id: playlist.id,
        name: playlist.name,
        trackIds: [for (final t in tracks) t.id],
      );
      final saved = await _playlists.updatePlaylist(filled);
      if (saved.isLeft()) {
        // No empty Replay left behind; the next launch tries again.
        await _playlists.deletePlaylist(playlist.id);
        return saved.map((_) => null);
      }
      await _log.setLastMonth(key);
      return right(filled);
    });
  }
}
