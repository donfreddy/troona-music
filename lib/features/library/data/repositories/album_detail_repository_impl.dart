import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/data/models/track_model.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';

final class AlbumDetailRepositoryImpl implements AlbumDetailRepository {
  final LocalAudioDataSource _source;
  final IsarLibraryDataSource _cache;

  const AlbumDetailRepositoryImpl({
    required LocalAudioDataSource source,
    required IsarLibraryDataSource cache,
  }) : _source = source,
       _cache = cache;

  @override
  Future<Either<Failure, Album>> getAlbumById(String id) async {
    try {
      final targetId = int.tryParse(id);
      if (targetId == null) {
        return left(const DatabaseFailure('Invalid album ID format'));
      }

      final tracks = await _cache.getTracksByAlbumId(targetId);
      if (tracks.isEmpty) {
        return left(const DatabaseFailure('Album not found'));
      }
      final firstTrack = tracks.first;

      return right(Album(
        id: firstTrack.albumId.toString(),
        name: firstTrack.album,
        artist: firstTrack.artist,
        artworkPath: firstTrack.artworkPath,
        artistId: firstTrack.artistId,
        trackCount: tracks.length,
      ));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Album>>> getAlbumsByArtistId(int artistId) async {
    try {
      final tracks = await _cache.getTracksByArtistId(artistId);
      
      final albumGroups = <String, List<TrackModel>>{};
      for (final t in tracks) {
        albumGroups.putIfAbsent(t.album, () => []).add(t);
      }

      final resultAlbums = albumGroups.values.map((group) {
        final firstTrack = group.first;
        return Album(
          id: firstTrack.albumId.toString(),
          name: firstTrack.album,
          artist: firstTrack.artist,
          artworkPath: firstTrack.artworkPath,
          artistId: firstTrack.artistId,
          trackCount: group.length,
        );
      }).toList();

      return right(resultAlbums);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  // @override
  // Future<Either<Failure, List<Track>>> getTracksByArtistId(int id) async {
  //   try {
  //     final tracks = await _cache.getTracksByArtistId(id);
  //     return right(tracks.map((t) => t.toEntity()).toList());
  //   } catch (e, st) {
  //     return left(ErrorHandler.handle(e, st));
  //   }
  // }

  @override
  Future<Either<Failure, List<Track>>> getTracksByAlbumId(int id) async {
    try {
      final tracks = await _cache.getTracksByAlbumId(id);
      return right(tracks.map((t) => t.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }
}
