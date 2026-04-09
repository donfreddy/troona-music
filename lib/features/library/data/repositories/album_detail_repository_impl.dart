import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/data/sources/local_audio_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
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

      final albums = await _source.getAlbums();
      final album = albums.where((a) => a.id == targetId).firstOrNull;

      if (album == null) {
        return left(const DatabaseFailure('Album not found'));
      }

      return right(album.toEntity());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Album>>> getAlbumsByArtistId(String id) async {
    try {
      final targetArtistId = int.tryParse(id);
      if (targetArtistId == null) {
        return left(const DatabaseFailure('Invalid artist ID format'));
      }

      final albums = await _source.getAlbums();
      final artistAlbums = albums
          .where((a) => a.artistId == targetArtistId)
          .map((a) => a.toEntity())
          .toList();

      return right(artistAlbums);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Track>>> getTracksByArtistId(int id) async {
    try {
      final tracks = await _cache.getTracksByArtistId(id);
      return right(tracks.map((t) => t.toEntity()).toList());
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

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
