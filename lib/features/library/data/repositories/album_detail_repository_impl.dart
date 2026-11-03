import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/data/sources/isar_library_data_source.dart';
import 'package:troona/features/library/domain/entities/album.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/repositories/album_detail_repository.dart';
import 'package:troona/features/library/domain/services/library_grouping.dart';

final class AlbumDetailRepositoryImpl implements AlbumDetailRepository {
  final IsarLibraryDataSource _cache;

  const AlbumDetailRepositoryImpl({required IsarLibraryDataSource cache})
    : _cache = cache;

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
      return right(
        LibraryGrouping.albumsOf([for (final t in tracks) t.toEntity()]).single,
      );
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<Album>>> getAlbumsByArtistId(int artistId) async {
    try {
      final tracks = await _cache.getAlbumTracksByArtistId(artistId);
      return right(
        LibraryGrouping.albumsOfArtist(artistId, [
          for (final t in tracks) t.toEntity(),
        ]),
      );
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
