import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/home/domain/entities/home_feed.dart';
import 'package:troona/features/home/domain/repositories/home_repository.dart';
import 'package:troona/features/library/data/models/playlist_model.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/artist.dart';

final class HomeRepositoryImpl implements HomeRepository {
  final IsarLibraryDataSource _db;

  const HomeRepositoryImpl({required IsarLibraryDataSource db}) : _db = db;

  @override
  Future<Either<Failure, HomeFeed>> getFeed() async {
    try {
      final results = await Future.wait([
        _db.getRecentTracks(limit: 4),
        _db.getUniqueArtists(limit: 5),
        _db.getUniqueAlbums(limit: 5),
        _db.getPlaylists(limit: 3),
      ]);

      final recentTracks = (results[0] as List<TrackModel>).map((t) => t.toEntity()).toList();
      
      final artists = (results[1] as List<TrackModel>).map((t) => Artist(
        id: t.artistId.toString(),
        name: t.artist,
        //artworkPath: t.artworkPath,
        trackCount: 0, albumCount: 0, // Optionnel ici
      )).toList();

      final albums = (results[2] as List<TrackModel>).map((t) => Album(
        id: t.albumId.toString(),
        name: t.album,
        artist: t.artist,
        artworkPath: t.artworkPath, artistId: 0, trackCount: 0,
        //year: null,
      )).toList();

      final playlists = (results[3] as List<PlaylistModel>).map((p) => p.toEntity()).toList();

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
