import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/history/domain/repositories/play_history_repository.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';
import 'package:troona/features/library/domain/entities/track.dart';

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
  Stream<void> get feedChanges => _history.changes;

  @override
  Future<Either<Failure, HomeFeed>> getFeed() async {
    try {
      final results = await Future.wait([
        _recentlyPlayed(),
        _db.getUniqueArtists(limit: 5),
        _db.getUniqueAlbums(limit: 5),
        _db.getPlaylists(limit: 3),
      ]);

      final recentTracks = results[0] as List<Track>;

      final artists = (results[1] as List<TrackModel>)
          .map(
            (t) => Artist(
              id: t.artistId.toString(),
              name: t.artist,
              //artworkPath: t.artworkPath,
              trackCount: 0,
              albumCount: 0, // Optionnel ici
            ),
          )
          .toList();

      final albums = (results[2] as List<TrackModel>)
          .map(
            (t) => Album(
              id: t.albumId.toString(),
              name: t.album,
              artist: t.artist,
              artworkPath: t.artworkPath,
              artistId: 0,
              trackCount: 0,
              //year: null,
            ),
          )
          .toList();

      final playlists = (results[3] as List<PlaylistModel>)
          .map((p) => p.toEntity())
          .toList();

      return right(
        HomeFeed(
          recentlyPlayed: recentTracks,
          yourArtists: artists,
          newAlbums: albums,
          yourPlaylists: playlists,
        ),
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
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
