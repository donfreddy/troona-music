import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/entities/listening_recap.dart';
import 'package:troona/features/history/domain/entities/listening_stats.dart';
import 'package:troona/features/history/domain/listening_day.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/history/domain/services/listening_moments.dart';
import 'package:troona/features/library/domain/entities/artist_credit.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';
import 'package:troona/features/library/domain/use_cases/get_tracks_by_ids_use_case.dart';

/// The recap of the week or month [day] falls in (a `ListeningDay` key).
/// A span without plays comes back with its dates and zeros, so the page
/// can still show it.
final class GetListeningRecapUseCase {
  final PlayHistoryRepository _history;
  final GetTracksByIdsUseCase _getTracksByIds;

  const GetListeningRecapUseCase(this._history, this._getTracksByIds);

  /// History needed before a span for its first plays to be trusted: a
  /// song last heard before the history began would count as discovered.
  static const discoveryLookback = 28;

  /// Songs and albums listed at most.
  static const topCount = 5;

  /// [today] bounds the days the span has lived, for When you listen: a
  /// month in progress has not had its last Sundays yet.
  Future<Either<Failure, ListeningRecap>> call(
    RecapPeriod period,
    int day, {
    required int today,
  }) async {
    final (first, last) = period.rangeOf(day);
    final result = await _history.listeningStats(
      firstDay: first,
      lastDay: last,
    );
    return result.fold(left, (stats) async {
      if (stats.plays == 0) {
        return right(
          ListeningRecap(
            period: period,
            firstDay: first,
            lastDay: last,
            plays: 0,
            listened: stats.listened,
            historyStart: stats.historyStart,
          ),
        );
      }
      return right(await _recap(period, first, last, today, stats));
    });
  }

  Future<ListeningRecap> _recap(
    RecapPeriod period,
    int first,
    int last,
    int today,
    ListeningStats stats,
  ) async {
    final ranked = stats.trackPlays.entries.toList()
      ..sort((a, b) {
        final byPlays = b.value.compareTo(a.value);
        return byPlays != 0 ? byPlays : a.key.compareTo(b.key);
      });
    // Tracks removed from the device since are skipped.
    final tracks = (await _getTracksByIds([
      for (final e in ranked) e.key,
    ])).getOrElse(() => const <Track>[]);

    final (artist, artistTrack, artistPlays) = _topArtist(
      tracks,
      stats.trackPlays,
    );
    final historyStart = stats.historyStart;

    return ListeningRecap(
      period: period,
      firstDay: first,
      lastDay: last,
      plays: stats.plays,
      listened: stats.listened,
      dayPlays: stats.dayPlays,
      topTracks: [
        for (final t in tracks.take(topCount))
          RankedTrack(t, stats.trackPlays[t.id]!),
      ],
      topArtist: artist,
      topArtistTrack: artistTrack,
      topArtistPlays: artistPlays,
      topAlbums: _topAlbums(tracks, stats.trackPlays),
      discoveries:
          historyStart != null && historyStart <= first - discoveryLookback
          ? stats.discoveries
          : null,
      moments: ListeningMoments.fromHours(
        stats.hourPlays,
        weekdayCounts: _weekdaysLived(
          max(first, historyStart ?? first),
          min(last, today),
        ),
      ),
      historyStart: historyStart,
    );
  }

  /// How many of each weekday, Monday first, the days from [first] to
  /// [last] hold: the span's days already lived, since the history began.
  static List<int> _weekdaysLived(int first, int last) {
    final counts = List.filled(7, 0);
    for (var d = first; d <= last; d++) {
      counts[ListeningDay.weekday(d) - 1]++;
    }
    return counts;
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

  /// Albums by plays of their songs, most played first; on a tie, the one
  /// whose top song ranks first. Songs without an album name are left out.
  static List<RankedAlbum> _topAlbums(
    List<Track> tracks,
    Map<String, int> plays,
  ) {
    final byAlbum = <int, int>{};
    final songs = <int, List<Track>>{};
    for (final t in tracks) {
      final name = t.album.trim().toLowerCase();
      if (name.isEmpty || name == '<unknown>') continue;
      byAlbum[t.albumId] = (byAlbum[t.albumId] ?? 0) + plays[t.id]!;
      (songs[t.albumId] ??= []).add(t);
    }
    // Insertion order is the rank of each album's top song.
    final order = byAlbum.keys.toList();
    final ids = [...order]
      ..sort((a, b) {
        final byPlays = byAlbum[b]!.compareTo(byAlbum[a]!);
        return byPlays != 0 ? byPlays : order.indexOf(a) - order.indexOf(b);
      });
    return [
      for (final id in ids.take(topCount))
        RankedAlbum(
          id: id,
          name: songs[id]!.first.album,
          cover: songs[id]!.firstWhere(
            (t) => t.artworkPath?.isNotEmpty ?? false,
            orElse: () => songs[id]!.first,
          ),
          plays: byAlbum[id]!,
        ),
    ];
  }
}
