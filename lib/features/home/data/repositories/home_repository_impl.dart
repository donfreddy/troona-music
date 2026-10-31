import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/entities/track_play_count.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/services/track_tags.dart';

final class HomeRepositoryImpl implements HomeRepository {
  final IsarLibraryDataSource _db;
  final PlayHistoryRepository _history;

  const HomeRepositoryImpl({
    required IsarLibraryDataSource db,
    required PlayHistoryRepository history,
  }) : _db = db,
       _history = history;

  /// Cards in the Recently Played grid.
  static const recentCount = 4;

  @override
  Stream<void> get feedChanges =>
      Rx.merge([_history.changes, _db.watchTracks(), _db.watchPlaylists()]);

  @override
  Future<Either<Failure, HomeFeed>> getFeed() async {
    try {
      // ── Phase 1: parallel queries (no inter-dependencies) ───────────────
      final results = await Future.wait([
        _recentlyPlayed(), // 0
        _db.getUniqueArtists(limit: 5), // 1
        _db.getUniqueAlbums(limit: 5), // 2
        _db.getPlaylists(limit: 3), // 3
        _history.topTrackIds(days: 7, limit: 5), // 4
        _db.getLikedTrackIds(), // 5
        _history.totalPlays(days: 7), // 6
      ]);

      final recentTracks = results[0] as List<Track>;

      final artists = (results[1] as List<TrackModel>)
          .map(
            (t) => Artist(
              id: t.artistId.toString(),
              name: TrackTags.artist(t.artist),
              trackCount: 0,
              albumCount: 0,
              artworkPath: t.artworkPath,
            ),
          )
          .toList();

      final albums = (results[2] as List<TrackModel>)
          .map(
            (t) => Album(
              id: t.albumId.toString(),
              name: t.album,
              artist: TrackTags.artist(t.artist),
              artworkPath: t.artworkPath,
              artistId: 0,
              trackCount: 0,
            ),
          )
          .toList();

      final playlists = (results[3] as List<PlaylistModel>)
          .map((p) => p.toEntity())
          .toList();

      // ── Phase 2: top weekly: needs track resolution ──────────────────
      final topIdsResult = results[4] as Either;
      final topCounts =
          topIdsResult.getOrElse(() => <String, int>{}) as Map<String, int>;
      final topWeekly = await _resolveTopWeekly(topCounts);

      // ── Phase 3: hidden gems: needs liked IDs + history ──────────────
      final likedIds = results[5] as Set<String>;
      final hiddenGems = await _resolveHiddenGems(likedIds);

      // Weekly play count
      final totalPlaysResult = results[6] as Either;
      final weeklyPlayCount = totalPlaysResult.getOrElse(() => 0) as int;

      return right(
        HomeFeed(
          recentlyPlayed: recentTracks,
          yourArtists: artists,
          newAlbums: albums,
          yourPlaylists: playlists,
          topWeekly: topWeekly,
          hiddenGems: hiddenGems,
          likesCount: likedIds.length,
          weeklyPlayCount: weeklyPlayCount,
        ),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  /// Resolves track IDs + play counts into [TrackPlayCount] entities.
  Future<List<TrackPlayCount>> _resolveTopWeekly(
    Map<String, int> counts,
  ) async {
    if (counts.isEmpty) return const [];
    final models = await _db.getTracksByIds(counts.keys.toList());
    final map = {for (final m in models) m.deviceId: m};
    return [
      for (final entry in counts.entries)
        if (map.containsKey(entry.key))
          TrackPlayCount(
            track: map[entry.key]!.toEntity(),
            playCount: entry.value,
          ),
    ];
  }

  /// Resolves forgotten liked track IDs into [Track] entities.
  Future<List<Track>> _resolveHiddenGems(Set<String> likedIds) async {
    final idsResult = await _history.forgottenTrackIds(likedIds);
    final ids = idsResult.getOrElse(() => const []);
    if (ids.isEmpty) return const [];
    final models = await _db.getTracksByIds(ids);
    return [for (final m in models) m.toEntity()];
  }

  /// Last played tracks first, topped up with the newest tracks so the
  /// grid stays full before enough has been played. Plays of tracks no
  /// longer in the library are skipped.
  Future<List<Track>> _recentlyPlayed() async {
    // Twice the need: plays of deleted tracks are dropped below.
    final ids = (await _history.recentTrackIds(
      limit: recentCount * 2,
    )).getOrElse(() => const []);
    final played = {
      for (final t
          in ids.isEmpty ? const <TrackModel>[] : await _db.getTracksByIds(ids))
        t.deviceId: t,
    };
    final tracks = [
      for (final id in ids) ?played[id],
    ].take(recentCount).toList();
    if (tracks.length < recentCount) {
      // Twice the need: enough even if every played track is among them.
      final newest = await _db.getRecentTracks(limit: recentCount * 2);
      for (final t in newest) {
        if (tracks.length == recentCount) break;
        if (!played.containsKey(t.deviceId)) tracks.add(t);
      }
    }
    return [for (final t in tracks) t.toEntity()];
  }

  @override
  Future<Either<Failure, int>> getTotalTrackCount() async {
    try {
      final count = await _db.countTracks();
      return right(count);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
