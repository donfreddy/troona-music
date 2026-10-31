import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/entities/weekly_recap.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';

/// The recap of the last finished week, Monday to Sunday: it changes on
/// Mondays only. Null when nothing was played that week.
final class GetWeeklyRecapUseCase {
  final PlayHistoryRepository _history;
  final GetTracksByIdsUseCase _getTracksByIds;

  const GetWeeklyRecapUseCase(this._history, this._getTracksByIds);

  /// History needed before a week for its first plays to be trusted: a
  /// song last heard before the history began would count as discovered.
  static const discoveryLookback = 28;

  Future<Either<Failure, WeeklyRecap?>> call({DateTime? now}) async {
    final today = ListeningDay.of(now ?? DateTime.now());
    final start = ListeningDay.weekStart(today) - 7;
    final result = await _history.listeningStats(
      firstDay: start,
      lastDay: start + 6,
    );
    return result.fold(left, (stats) async {
      if (stats.plays == 0) return right(null);
      return right(await _recap(start, stats));
    });
  }

  Future<WeeklyRecap> _recap(int start, ListeningStats stats) async {
    final ranked = stats.trackPlays.entries.toList()
      ..sort((a, b) {
        final byPlays = b.value.compareTo(a.value);
        return byPlays != 0 ? byPlays : a.key.compareTo(b.key);
      });
    // Tracks removed from the device since are skipped.
    final tracks = (await _getTracksByIds([
      for (final e in ranked) e.key,
    ])).getOrElse(() => const <Track>[]);

    final topTrack = tracks.firstOrNull;
    final (artistTrack, artistPlays) = _topArtist(tracks, stats.trackPlays);
    final historyStart = stats.historyStart;

    return WeeklyRecap(
      weekStart: ListeningDay.date(start),
      plays: stats.plays,
      listened: stats.listened,
      topTrack: topTrack,
      topTrackPlays: topTrack == null ? 0 : stats.trackPlays[topTrack.id]!,
      topArtistTrack: artistTrack,
      topArtistPlays: artistPlays,
      discoveries:
          historyStart != null && historyStart <= start - discoveryLookback
          ? stats.discoveries
          : null,
    );
  }

  /// The artist with the most plays, through its most played track (tracks
  /// come ranked), ignoring files without an artist tag.
  static (Track?, int) _topArtist(List<Track> tracks, Map<String, int> plays) {
    final byArtist = <String, int>{};
    final firstTrack = <String, Track>{};
    for (final t in tracks) {
      final name = t.artist.trim();
      if (TrackTags.isUnknownArtist(name)) continue;
      byArtist[name] = (byArtist[name] ?? 0) + plays[t.id]!;
      firstTrack.putIfAbsent(name, () => t);
    }
    if (byArtist.isEmpty) return (null, 0);
    // Ties go to the artist whose own top track ranks first.
    var best = byArtist.keys.first;
    for (final name in byArtist.keys) {
      if (byArtist[name]! > byArtist[best]!) best = name;
    }
    return (firstTrack[best], byArtist[best]!);
  }
}
