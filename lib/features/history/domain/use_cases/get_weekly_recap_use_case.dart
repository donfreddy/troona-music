import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/entities/weekly_recap.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
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
    final (artist, artistTrack, artistPlays) = _topArtist(
      tracks,
      stats.trackPlays,
    );
    final historyStart = stats.historyStart;

    return WeeklyRecap(
      weekStart: ListeningDay.date(start),
      plays: stats.plays,
      listened: stats.listened,
      topTrack: topTrack,
      topTrackPlays: topTrack == null ? 0 : stats.trackPlays[topTrack.id]!,
      topArtist: artist,
      topArtistTrack: artistTrack,
      topArtistPlays: artistPlays,
      discoveries:
          historyStart != null && historyStart <= start - discoveryLookback
          ? stats.discoveries
          : null,
    );
  }

  /// The artist credited on the most plays, with their most played track
  /// (tracks come ranked), ignoring files without an artist tag. A
  /// collaboration counts for each of its artists.
  static (ArtistCredit?, Track?, int) _topArtist(
    List<Track> tracks,
    Map<String, int> plays,
  ) {
    final byArtist = <int, int>{};
    final credit = <int, ArtistCredit>{};
    final firstTrack = <int, Track>{};
    for (final t in tracks) {
      for (final c in t.credits) {
        if (TrackTags.isUnknownArtist(c.name)) continue;
        byArtist[c.id] = (byArtist[c.id] ?? 0) + plays[t.id]!;
        credit.putIfAbsent(c.id, () => c);
        firstTrack.putIfAbsent(c.id, () => t);
      }
    }
    if (byArtist.isEmpty) return (null, null, 0);
    // Ties go to the artist whose own top track ranks first.
    var best = byArtist.keys.first;
    for (final id in byArtist.keys) {
      if (byArtist[id]! > byArtist[best]!) best = id;
    }
    return (credit[best], firstTrack[best], byArtist[best]!);
  }
}
